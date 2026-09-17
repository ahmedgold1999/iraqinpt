// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:js' as js;

void removeWebLoader() {
  try {
    js.context.callMethod('removeLoader');
  } catch (e) {
    // ignore: avoid_print
    print('Web loader removal failed: $e');
  }
}

/// نطق فوري في المتصفح باللغتين العربية والإنجليزية باستخدام Web Speech API المدمجة
void speakWebText(String text, String lang) {
  try {
    final encodedText = jsonEncode(text);
    js.context.callMethod('eval', [
      '''
      (function() {
        if ('speechSynthesis' in window) {
          window.speechSynthesis.cancel();
          var utterance = new SpeechSynthesisUtterance($encodedText);
          utterance.lang = '$lang';
          utterance.rate = 0.95;
          utterance.pitch = 1.0;

          // البحث عن أفضل صوت مطابق للغة (العربية أو الإنجليزية)
          var voices = window.speechSynthesis.getVoices();
          if (voices && voices.length > 0) {
            var targetLang = '$lang'.toLowerCase();
            var matchedVoice = voices.find(function(v) {
              return v.lang.toLowerCase().startsWith(targetLang.substring(0, 2));
            });
            if (matchedVoice) {
              utterance.voice = matchedVoice;
            }
          }

          window.speechSynthesis.speak(utterance);
        }
      })();
      '''
    ]);
  } catch (e) {
    // ignore: avoid_print
    print('Web speech failed: $e');
  }
}

void stopWebSpeech() {
  try {
    js.context.callMethod('eval', [
      '''
      (function() {
        if ('speechSynthesis' in window) {
          window.speechSynthesis.cancel();
        }
      })();
      '''
    ]);
  } catch (e) {
    // ignore: avoid_print
    print('Web speech stop failed: $e');
  }
}
