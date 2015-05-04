KBHit kb;

int recording;
0 => recording;

0 => int voice;
60::second => dur max_record_duration;
Dyno noise_gate;
noise_gate.gate();
Gain input_gain;
8.0=> input_gain.gain;
adc => input_gain => LiSa loop => dac;
max_record_duration => loop.duration;

// 2.5 => loop.gain;
loop.feedback(0.0);
0::ms => loop.recRamp;

dur start_pos;
time start_time;
dur real_duration;
int char;
<<<"Ready">>>;
while (true) {
  kb => now;

  while (kb.more()) {
    kb.getchar() => char;
    if (char == 32) {
      if (recording) {
        0 => recording;
        now - start_time => real_duration;
        <<< "Real duration: " , real_duration >>>;
        loop.loopEnd(voice, loop.playPos(voice));
        loop.loopStart(voice, start_pos);
      }
      else {
        1 => recording;
        loop.play(voice, 0);
        voice++;
        loop.playPos(voice, loop.recPos());
        // loop.recPos(loop.playPos(voice));
        loop.rate(voice, 1);
        loop.play(voice, 1);
        loop.loop(voice, 1);
        // loop.voiceGain(voice, 12.0);
        max_record_duration => real_duration;
        now => start_time;
        loop.playPos(voice) => start_pos;
        <<<"Start time: ", start_time >>>;
        <<<"Voice: ", voice >>>;
      }

      <<< "recording: ", recording >>>;
      loop.record(recording);
      loop.play(1);
    } else {
      <<<"Unhandled key: ", char >>>;
    }
  }
}
