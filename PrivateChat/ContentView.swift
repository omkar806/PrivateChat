//
//  ContentView.swift
//  gemma-mediapipe
//
//  Created by Omkar Malpure on 27/03/24.
//

import SwiftUI
import MediaPipeTasksGenAI
struct ContentView: View {  
    @State private var messageText = ""
    @State var messages: [String] = ["Welcome to AI Bot 2.0!"]
    @State private var init_model: LlmInference?
    @State private var isGeneratingResponse = false
     @State private var currentStreamingMessage = ""
    @State private var streamingTokens: [String] = []
    
    func initialise_llmIfNeeded() {
        if init_model == nil {
            init_model = initialise_llm()
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

            }
        }
    }
   
    
    
    func sendMessage(message: String) {
        guard !message.isEmpty else { return }
        
        withAnimation {
            messages.append("[USER]" + message)
            self.messageText = ""
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
