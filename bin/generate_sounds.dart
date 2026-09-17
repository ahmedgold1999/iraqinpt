import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/audio');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  // 1. Correct Answer: Pleasant Chime (C5 -> E5 -> G5)
  generateWavFile('assets/audio/correct.wav', durationSec: 0.4, sampleRate: 44100, generator: (t, total) {
    double freq1 = 523.25; // C5
    double freq2 = 659.25; // E5
    double freq3 = 783.99; // G5
    double envelope = (1.0 - t / total) * exp(-2.0 * t);
    double tone1 = sin(2 * pi * freq1 * t) * (t < 0.15 ? 0.6 : 0.2);
    double tone2 = sin(2 * pi * freq2 * t) * (t >= 0.08 && t < 0.25 ? 0.7 : 0.2);
    double tone3 = sin(2 * pi * freq3 * t) * (t >= 0.16 ? 0.8 : 0.0);
    return (tone1 + tone2 + tone3) * envelope * 0.7;
  });

  // 2. Wrong Answer: Soft low double-buzz (B2 / G2)
  generateWavFile('assets/audio/wrong.wav', durationSec: 0.35, sampleRate: 44100, generator: (t, total) {
    double freq = t < 0.15 ? 180.0 : 140.0;
    double envelope = (1.0 - t / total) * (0.5 + 0.5 * sin(2 * pi * 20 * t));
    return sin(2 * pi * freq * t) * envelope * 0.5;
  });

  // 3. Quiz Complete / Victory: Multi-tone celebratory Fanfare
  generateWavFile('assets/audio/complete.wav', durationSec: 0.8, sampleRate: 44100, generator: (t, total) {
    double envelope = (1.0 - t / total);
    double f;
    if (t < 0.2) {
      f = 523.25; // C5
    } else if (t < 0.4) {
      f = 659.25; // E5
    } else if (t < 0.6) {
      f = 783.99; // G5
    } else {
      f = 1046.50; // C6
    }
    double harmonics = sin(2 * pi * f * t) + 0.4 * sin(4 * pi * f * t);
    return harmonics * envelope * 0.6;
  });

  // 4. Click / Tap: Short subtle tactile click
  generateWavFile('assets/audio/click.wav', durationSec: 0.05, sampleRate: 44100, generator: (t, total) {
    double envelope = exp(-80.0 * t);
    return sin(2 * pi * 800.0 * t) * envelope * 0.4;
  });

  print('✅ All 4 audio files generated successfully in assets/audio/!');
}

void generateWavFile(String path, {
  required double durationSec,
  required int sampleRate,
  required double Function(double t, double total) generator,
}) {
  int numSamples = (durationSec * sampleRate).toInt();
  int numChannels = 1;
  int bitsPerSample = 16;
  int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  int blockAlign = numChannels * (bitsPerSample ~/ 8);
  int dataSize = numSamples * numChannels * (bitsPerSample ~/ 8);
  int chunkSize = 36 + dataSize;

  final bytes = BytesBuilder();

  // RIFF header
  bytes.add('RIFF'.codeUnits);
  bytes.add(_int32(chunkSize));
  bytes.add('WAVE'.codeUnits);

  // fmt subchunk
  bytes.add('fmt '.codeUnits);
  bytes.add(_int32(16)); // Subchunk1Size for PCM
  bytes.add(_int16(1));  // AudioFormat (1 = PCM)
  bytes.add(_int16(numChannels));
  bytes.add(_int32(sampleRate));
  bytes.add(_int32(byteRate));
  bytes.add(_int16(blockAlign));
  bytes.add(_int16(bitsPerSample));

  // data subchunk
  bytes.add('data'.codeUnits);
  bytes.add(_int32(dataSize));

  // Samples
  for (int i = 0; i < numSamples; i++) {
    double t = i / sampleRate;
    double sampleVal = generator(t, durationSec).clamp(-1.0, 1.0);
    int intSample = (sampleVal * 32767).toInt().clamp(-32768, 32767);
    bytes.add(_int16(intSample));
  }

  File(path).writeAsBytesSync(bytes.toBytes());
}

Uint8List _int16(int value) {
  return Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);
}

Uint8List _int32(int value) {
  return Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);
}
