import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/providers/preference_provider.dart';

class EditKeywordsPage extends StatefulWidget {
  @override
  _EditKeywordsPageState createState() => _EditKeywordsPageState();
}

class _EditKeywordsPageState extends State<EditKeywordsPage> {
  late List<String> likes;
  late List<String> dislikes;
  List<String> availableKeywords = [
    '풍경',
    '속도',
    '안전',
    '신호',
    '통행량',
    '오르막',
  ]; // 수정 가능한 모든 키워드

  @override
  void initState() {
    super.initState();
    final preferenceProvider = Provider.of<PreferenceProvider>(context, listen: false);
    likes = List<String>.from(preferenceProvider.likes);
    dislikes = List<String>.from(preferenceProvider.dislikes);

    // 나머지 키워드 리스트에서 이미 선택된 것을 제외
    availableKeywords.removeWhere((keyword) => likes.contains(keyword) || dislikes.contains(keyword));
  }

  void _onSave(BuildContext context) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context, listen: false);
    preferenceProvider.setLikes(likes);
    preferenceProvider.setDislikes(dislikes);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('취향 키워드 수정하기'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildKeywordSection('좋아요!', Colors.green, likes),
                _buildKeywordSection('싫어요!', Colors.red, dislikes),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  '사용 가능한 키워드',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: DragTarget<String>(
                    onAccept: (data) {
                      setState(() {
                        availableKeywords.add(data);
                        likes.remove(data);
                        dislikes.remove(data);
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Wrap(
                        spacing: 10,
                        children: availableKeywords
                            .map((keyword) => Draggable<String>(
                          data: keyword,
                          child: _buildKeywordChip(keyword, Colors.grey),
                          feedback: _buildKeywordChip(keyword, Colors.grey.withOpacity(0.5)),
                          childWhenDragging: _buildKeywordChip(keyword, Colors.grey.withOpacity(0.3)),
                        ))
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
              ),
              onPressed: () => _onSave(context),
              child: const Text(
                '키워드 저장하기',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordSection(String title, Color color, List<String> keywords) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Expanded(
            child: DragTarget<String>(
              onAccept: (data) {
                setState(() {
                  if (title == '좋아요!') {
                    likes.add(data);
                  } else {
                    dislikes.add(data);
                  }
                  availableKeywords.remove(data);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Wrap(
                  spacing: 10,
                  children: keywords
                      .map((keyword) => Draggable<String>(
                    data: keyword,
                    child: _buildKeywordChip(keyword, color),
                    feedback: _buildKeywordChip(keyword, color.withOpacity(0.5)),
                    childWhenDragging: _buildKeywordChip(keyword, color.withOpacity(0.3)),
                  ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordChip(String keyword, Color color) {
    return Chip(
      label: Text(
        keyword,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
      deleteIcon: Icon(Icons.close, color: Colors.white),
      onDeleted: () {
        setState(() {
          likes.remove(keyword);
          dislikes.remove(keyword);
          availableKeywords.remove(keyword);
        });
      },
    );
  }
}
