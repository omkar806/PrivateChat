//
//  SecondView.swift
//  gemma-mediapipe
//
//  Created by Omkar Malpure on 27/03/24.
//

import SwiftUI
import MediaPipeTasksGenAI
struct SecondView: View {
    var data: String
  
    @State private var chunks : [String] = []
    @State private var embeddings : [[Float]] = []
    @State private var messageText = ""
    @State var messages: [String] = ["Welcome to AI Bot 2.0!"]
    @State private var IndexArray :[Index] = []
     // Initialize once
//    var init_model = initialise_llm()
    @State private var init_model: LlmInference?
    @State private var json_data:String? = ""
    @State private var similarity_results  = []
    @State private var isGeneratingResponse = false
     @State private var currentStreamingMessage = ""
    @State private var streamingTokens: [String] = []
    
    func initialise_llmIfNeeded() {
        if init_model == nil {
            init_model = initialise_llm()
//            let user_input = data
//            let user_input = data+"Can you structure this data into json with appropriate format?"
//            do{
//                json_data = try init_model?.generateResponse(inputText: user_input)
//            }
//            catch{
//                print(error.localizedDescription)
//            }
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("AI Bot")
                    .font(.largeTitle)
                    .bold()

                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color.blue)
                
            }

            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack {
                        // Regular messages
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                            MessageView(message: message)
                                .id(index)
                        }
                        
                        // Streaming message
                        if !streamingTokens.isEmpty {
                            HStack {
                                Text(streamingTokens.joined())
                                    .padding()
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(10)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 10)
                                    .animation(.easeInOut(duration: 0.2), value: streamingTokens)
                                Spacer()
                            }
                            .id("streaming")
                        }
                    }
                }
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        scrollView.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
                .onChange(of: streamingTokens) { _ in
                    withAnimation {
                        scrollView.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }
            .background(Color.gray.opacity(0.1))

            

        

            

            // Contains the Message bar
            HStack {
                TextField("Type something", text: $messageText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .disabled(isGeneratingResponse)
                    .onSubmit {

                        sendMessage(message: messageText)

                    }

//                Button {
//                    sendMessage(message: messageText)
//
//                } label: {
//                    Image(systemName: "paperplane.fill")
//                }
//                .font(.system(size: 26))
//                .padding(.horizontal, 10)
                Button {
                    if isGeneratingResponse {
                        // Add logic to cancel streaming if needed
                        isGeneratingResponse = false
                    } else {
                        sendMessage(message: messageText)
                    }
                } label: {
                    Image(systemName: isGeneratingResponse ? "stop.fill" : "paperplane.fill")
                }
                .font(.system(size: 26))
                .padding(.horizontal, 10)
                .disabled(messageText.isEmpty && !isGeneratingResponse)
                
                
            }
            .padding()
            .onAppear{
                initialise_llmIfNeeded()
//                vectorizeChunks(data)
//                On_appear(data)
            }
        }
    }
   
    func On_appear(_ data : String){
//        do{
//            var user_input = data + "You will be acting as a Hushh Bot.You will be provided with some Receipt or Invoice data and you have to answer questions based on that.Don't Give a response for this prompt.Also please be aware of previous questions and responses."
//            let response = try init_model.generateResponse(inputText: user_input)
//        }
//        catch{
//            print("\(error.localizedDescription)")
//        }
        //Generate embeddings
//    let init_embedding_model = DistilbertEmbeddings()
//        let sent_embedding =  init_embedding_model.encode(sentence: data)
//        
//        print(sent_embedding!)
//        print(sent_embedding?.count ?? "No embeddings generated")

    }
    
    
    func sendMessage(message: String) {
        guard !message.isEmpty else { return }
        
        withAnimation {
            messages.append("[USER]" + message)
            self.messageText = ""
            search_index(message)
            
            Task {
                await generateStreamingResponse(prompt: message)
            }
        }
    }
    
    func generateStreamingResponse(prompt: String) async {
        isGeneratingResponse = true
        streamingTokens = []
        
        do {
            guard let model = init_model else {
                throw NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not initialized"])
            }
            
            let resultStream = model.generateResponseAsync(inputText: prompt)
            
            for try await token in resultStream {
                guard isGeneratingResponse else { break } // Check if we should stop
                
                await MainActor.run {
                    withAnimation(.spring(duration: 0.2)) {
                        streamingTokens.append(token)
                    }
                }
                
                // Add a small delay to make the token streaming visible
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            }
            
            // Once streaming is complete, add the full message to messages array
            await MainActor.run {
                let fullMessage = streamingTokens.joined()
                messages.append(fullMessage)
                streamingTokens = []
                isGeneratingResponse = false
            }
            
        } catch {
            await MainActor.run {
                messages.append("Error generating response: \(error.localizedDescription)")
                streamingTokens = []
                isGeneratingResponse = false
            }
        }
    }
    
    
    
    
//    func sendMessage(message: String) {
//      
//        withAnimation {
//            messages.append("[USER]" + message)
//            self.messageText = ""
//            search_index(message)
//            print("Similarity Search results")
//            print(similarity_results)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                withAnimation {
//
//                    messages.append(botResponse(prompt: message) ?? "Nothing")
//                }
//            }
//        }
//    }
//    func botResponse(prompt:String)->String?{
//        var response :String? = ""
//        var user_input = prompt
//        do{
//            response = try init_model?.generateResponse(inputText: user_input)
//        }
//        catch{
//            print("Error while generating response!!")
//        }
//        return response
//    }

    
    //Splitting the text , creating embeddings and storing it in an Index
    
    func vectorizeChunks(_ str : String) {
        Task {
            let splitter = RecursiveTokenSplitter(withTokenizer: BertTokenizer())
            let (splitText, _) = splitter.split(text: data,chunkSize: 25 , overlapSize: 7)
            
            chunks = splitText
            print("Printing Chunks")
            print(chunks)
            embeddings = []
            let embeddingModel = DistilbertEmbeddings()
            
            for chunk in chunks {
                if let embedding = embeddingModel.encode(sentence: chunk) {
                    embeddings.append(embedding)
                }
            }
            
            
            
            
            
        }
    }
    
    
    func search_index(_ qry:String){
        
        var similarities : [Int:Float] = [:]
        
        for idx in IndexArray.indices {
            let indexx = IndexArray[idx]
            let similarity_score = cosineSimilarity(DistilbertEmbeddings().encode(sentence: qry)!,indexx.embeddings ) // Assuming qryEmbeddings is the embeddings for the query
            similarities[idx] = similarity_score
        }
    
        let sortedSimilarities = similarities.sorted { $0.value < $1.value }
        for idxx in sortedSimilarities.indices {
            similarity_results.append(chunks[idxx])
        }
        
    }
    
    // Define a function to calculate similarity between two embeddings
    func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        // Calculate dot product
        let dotProduct = zip(embedding1, embedding2).map { $0 * $1 }.reduce(0, +)
        
        // Calculate magnitudes
        let magnitude1 = sqrt(embedding1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(embedding2.map { $0 * $0 }.reduce(0, +))
        
        // Calculate cosine similarity
        guard magnitude1 != 0 && magnitude2 != 0 else { return 0 } // Avoid division by zero
        return dotProduct / (magnitude1 * magnitude2)
    }
    
}

struct MessageView: View {
    let message: String
    
    var body: some View {
        if message.contains("[USER]") {
            let newMessage = message.replacingOccurrences(of: "[USER]", with: "")
            HStack {
                Spacer()
                Text(newMessage)
                    .padding()
                    .foregroundColor(Color.white)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        } else {
            HStack {
                Text(message)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                Spacer()
            }
        }
    }
}


#Preview {
    SecondView(data: "")
}
