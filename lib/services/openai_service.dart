import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'system_prompt.dart'; // {{ edit_1 }} Imported system_prompt.dart

class OpenAIService with ChangeNotifier {
  OpenAIService() {
    OpenAI.apiKey = 'sk-FEYtSBBL3ribPTxx1fngsASLcu_eBSAWV9IAfgsVbdT3BlbkFJnYIq86GEe4wnreHxwGoi6gY2UpiSkF8oBgbD1W9RwA';
  }

  Future<String> generateTradingStrategy(String prompt) async {
    try {
      // Prepare the messages for the chat model
      final messages = [
        // {{ edit_2 }} Replaced inline system prompt with imported systemPrompt
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
          ],
        ),
      ];

      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini",
        messages: messages,
        maxTokens: 500,
        temperature: 0.7,
      );

      // Safely access the assistant's response
      final responseText = chatCompletion.choices.isNotEmpty 
          ? chatCompletion.choices.first.message.content?.first.text?.trim() 
          : null;

      return responseText ?? 'No response received from the model.';
    } catch (e) {
      print('Error generating strategy: $e');
      return 'An error occurred while generating the strategy.';
    }
  }
}