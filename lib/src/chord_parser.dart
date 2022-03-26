import 'dart:math';

import 'package:flutter/material.dart';
import 'model/chord_lyrics_document.dart';
import 'model/chord_lyrics_line.dart';

class ChordProcessor {
  final BuildContext context;
  ChordProcessor(this.context);

  /// Process the text to get the parsed ChordLyricsDocument
  ChordLyricsDocument processText({
    required String text,
    required TextStyle lyricsStyle,
    required chordStyle,
    double widgetWidth = 0,
    int transposeIncrement = 0,
  }) {
    List<ChordLyricsLine> _chordLyricsLines = [];
    ChordLyricsLine _chordLyricsLine = ChordLyricsLine([], '');
    ChordLyricsLine _chordLyricsBuffer = ChordLyricsLine([], '');
    String lyricsFromLastChord = '';
    bool chordYetInLine = false;
    bool chordYetInBuffer = false;
    String lyricsFromNewLineToFirstChord = '';
    String lyricsFromBufferToFirstChord = '';
    String chordsSoFar = '';
    String previousChord = '';
    String character = '';
    String transposedChord = '';
    double leadingSpace = 0;
    double sizeOfLeadingLyrics = 0;
    bool chordHasStarted = false;

    //Keep populating lyrics and chords until it gets too long for the screen.
    //
    //Keep a buffer that gets added to the actual line once we hit a space.
    //If we have a chord or lyric that causes overflow, break and write current line.
    //Keep the buffer (adjusting variables appropriately) and use for next line.
    //Need to keep some variables to track the lyrics at the start of line or buffer.
    //This helps when we need to adjust the leadingSpace before the first chord in the new line.
    for (var i = 0; i < text.length; i++) {
      character = text[i];
      if (character == ']') {
        //End of chord detected

        //Transpose chord if required
        transposedChord = transposeChord(
          chordsSoFar,
          transposeIncrement,
        );

        //Reset variables
        chordsSoFar = '';
        chordHasStarted = false;

        //Check width of chord buffer
        double chordBufferWidth = 0;
        String textToCheck = '';
        _chordLyricsBuffer.chords.forEach((element) {
          chordBufferWidth += element.leadingSpace;
          textToCheck += element.chordText;
        });
        chordBufferWidth += textWidth(textToCheck, chordStyle);

        final thisChordWidth = textWidth(transposedChord, chordStyle);

        if (textWidth(_chordLyricsLine.lyrics, lyricsStyle) +
                chordBufferWidth +
                thisChordWidth >
            widgetWidth) {
          //overflow detected with the chords

          //Add current line
          _chordLyricsLines.add(_chordLyricsLine);

          //reset variables
          _chordLyricsLine = ChordLyricsLine([], '');
          chordHasStarted = false;
          leadingSpace = 0;

          previousChord = transposedChord;

          //Add current chord to buffer
          _chordLyricsBuffer.chords.add(Chord(leadingSpace, transposedChord));

          //Adjust first chord if needed
          if (chordYetInBuffer) {
            _chordLyricsBuffer.chords.first.leadingSpace =
                textWidth(lyricsFromBufferToFirstChord, lyricsStyle);
            chordYetInLine = true;
          }

          //Add buffer to line
          _chordLyricsLine.chords.addAll(_chordLyricsBuffer.chords);
          _chordLyricsLine.lyrics += _chordLyricsBuffer.lyrics;

          //Clear buffer
          _chordLyricsBuffer.lyrics = '';
          _chordLyricsBuffer.chords.clear();
          chordYetInBuffer = false;
        } else {
          //Adding Chord to buffer

          //Check to see if we are at the first chord in a new line
          final lyricsToCheck = chordYetInLine
              ? lyricsFromLastChord
              : lyricsFromNewLineToFirstChord;
          sizeOfLeadingLyrics = textWidth(lyricsToCheck, lyricsStyle);

          //Find the leading space of the chord based on lyrics and previous chord
          final lastChordWidth = textWidth(previousChord, chordStyle);
          leadingSpace = (sizeOfLeadingLyrics - lastChordWidth);
          leadingSpace = max(0, leadingSpace);

          //Add the chord to the buffer
          _chordLyricsBuffer.chords.add(Chord(leadingSpace, transposedChord));

          previousChord = transposedChord;
          chordYetInBuffer = true;
          chordYetInLine = true;
        }

        lyricsFromLastChord = '';
      } else if (character == '[') {
        chordHasStarted = true;
      } else {
        if (chordHasStarted) {
          chordsSoFar += character;
        } else {
          //This character is a lyric and not a chord
          if (textWidth(
                  _chordLyricsLine.lyrics +
                      _chordLyricsBuffer.lyrics +
                      character,
                  lyricsStyle) >
              widgetWidth) {
            //Overflow detected with the lyrics.

            //Add current line
            _chordLyricsLines.add(_chordLyricsLine);

            //reset variables
            _chordLyricsLine = ChordLyricsLine([], '');
            chordHasStarted = false;

            lyricsFromLastChord += character;

            //Adjust first chord if needed
            if (chordYetInBuffer) {
              _chordLyricsBuffer.chords.first.leadingSpace =
                  textWidth(lyricsFromBufferToFirstChord, lyricsStyle);
            }

            //Add buffer to line
            _chordLyricsLine.chords.addAll(_chordLyricsBuffer.chords);
            _chordLyricsLine.lyrics += _chordLyricsBuffer.lyrics + character;

            //Flag if there is a chord in the line.
            if (_chordLyricsLine.chords.isEmpty) {
              chordYetInLine = false;
              previousChord = '';
            } else {
              chordYetInLine = true;
            }

            //Clear buffer
            _chordLyricsBuffer.lyrics = '';
            _chordLyricsBuffer.chords.clear();
            chordYetInBuffer = false;

            //Now on a new line so this is needed
            lyricsFromNewLineToFirstChord = _chordLyricsLine.lyrics;
          } else if (character == '\n') {
            //New line detected

            //Add line to lines
            _chordLyricsLines.add(_chordLyricsLine);

            //Add buffer to next line
            _chordLyricsLine.chords.addAll(_chordLyricsBuffer.chords);
            _chordLyricsLine.lyrics += _chordLyricsBuffer.lyrics;

            //Reset buffers. As this is a clean break we can reset all variables.
            lyricsFromNewLineToFirstChord = '';
            lyricsFromBufferToFirstChord = '';
            lyricsFromLastChord = '';
            _chordLyricsBuffer.lyrics = '';
            _chordLyricsBuffer.chords.clear();
            chordYetInLine = false;
            chordYetInBuffer = false;
            _chordLyricsLine = ChordLyricsLine([], '');
            chordHasStarted = false;
            previousChord = '';
          } else {
            //Add lyric to buffer
            _chordLyricsBuffer.lyrics += character;
            lyricsFromLastChord += character;
            if (!chordYetInBuffer) lyricsFromBufferToFirstChord += character;
            if (!chordYetInLine) lyricsFromNewLineToFirstChord += character;

            if (character == ' ') {
              //Found a space. Write current buffer to the line.
              _chordLyricsLine.chords.addAll(_chordLyricsBuffer.chords);
              _chordLyricsLine.lyrics += _chordLyricsBuffer.lyrics;

              //Reset buffers and variables
              lyricsFromBufferToFirstChord = '';
              _chordLyricsBuffer.lyrics = '';
              _chordLyricsBuffer.chords.clear();
              chordYetInBuffer = false;
            }
          }
        }
      }
    }

    //Now at the end of the text. Save the buffer as a line.
    _chordLyricsLine.lyrics += _chordLyricsBuffer.lyrics;
    _chordLyricsLines.add(_chordLyricsLine);

    return ChordLyricsDocument(_chordLyricsLines);
  }

  /// Return the textwidth of the text in the given style
  double textWidth(String text, TextStyle textStyle) {
    return (TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout())
        .size
        .width;
  }

  /// Transpose the chord text by the given increment
  String transposeChord(String chord, int increment) {
    if (increment == 0) return chord;

    final cycle = [
      "C",
      "C#",
      "D",
      "D#",
      "E",
      "F",
      "F#",
      "G",
      "G#",
      "A",
      "A#",
      "B"
    ];
    String el = chord[0];
    if (chord.length > 1 && chord[1] == '#') {
      el += "#";
    }
    final ind = cycle.indexOf(el);
    if (ind == -1) return chord;

    final newInd = (ind + increment + cycle.length) % cycle.length;
    final newChord = cycle[newInd];
    return newChord + chord.substring(el.length);
  }
}
