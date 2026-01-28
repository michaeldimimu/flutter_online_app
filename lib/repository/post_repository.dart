import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_online_app/model/post.dart';
import 'package:http/http.dart' as http;

class PostRepository {
  // Using DummyJSON as an alternative - it's more reliable and less likely to be blocked
  final String baseUrl = "https://dummyjson.com";

  Future<List<Post>> fetchPosts() async {
    try {
      debugPrint('Attempting to fetch posts from: $baseUrl/posts');

      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - please check your internet connection');
        },
      );

      debugPrint('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // DummyJSON returns posts in a "posts" array
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        List<dynamic> postsData = jsonResponse['posts'] ?? [];

        debugPrint('Successfully fetched ${postsData.length} posts');

        // Convert DummyJSON format to our Post format
        return postsData.map((dynamic item) {
          return Post(
            id: item['id'],
            userId: item['userId'] ?? 1,
            title: item['title'] ?? '',
            body: item['body'] ?? '',
          );
        }).toList();
      } else {
        debugPrint('Failed with status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception("Failed to load posts (Status: ${response.statusCode})");
      }
    } on SocketException catch (e) {
      debugPrint('SocketException: $e');
      throw Exception("No internet connection. Please check your network settings.");
    } on FormatException catch (e) {
      debugPrint('FormatException: $e');
      throw Exception("Invalid response format from server");
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      throw Exception("Failed to load posts: $e");
    }
  }

  Future<Post> createPost(Post post) async {
    try {
      debugPrint('Attempting to create post at: $baseUrl/posts/add');

      final response = await http.post(
        Uri.parse('$baseUrl/posts/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': post.title,
          'body': post.body,
          'userId': post.userId,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - please check your internet connection');
        },
      );

      debugPrint('Create post response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Post created successfully');
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return Post(
          id: responseData['id'],
          userId: responseData['userId'] ?? post.userId,
          title: responseData['title'] ?? post.title,
          body: responseData['body'] ?? post.body,
        );
      } else {
        debugPrint('Failed to create post. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception("Failed to create post (Status: ${response.statusCode})");
      }
    } on SocketException catch (e) {
      debugPrint('SocketException: $e');
      throw Exception("No internet connection. Please check your network settings.");
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception("Failed to create post: $e");
    }
  }
}