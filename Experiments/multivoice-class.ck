KBHit kb;
Dyno noise_gate;
noise_gate.gate();
int char;
Looper looper;
looper.connect(adc, dac);
<<<"Ready">>>;

while (true) {
  kb => now;

  while (kb.more()) {
    kb.getchar() => char;
    if (char == 32) {
      looper.start_stop();
    }
    else if (char == 127) {
        looper.delete_loop();
    } else {
        <<<"Unhandled key: ", char >>>;
    }

  }
}

public class Looper {
    dur start_pos;
    time start_time;
    dur real_duration;
    LiSa loop;
    0 => int recording;
    0 => int voice; // current recording voice
    int voice_count;
    60::second => static dur max_record_duration;
    max_record_duration => loop.duration;
    // 2.5 => loop.gain;
    loop.feedback(0.0);
    0::ms => loop.recRamp;
    8.0 => float gain;

    fun int _add_voice() {
        voice++;
        return voice;
    }

    fun int _voice() {
        return voice;
    }

    fun void connect( UGen l, UGen r ) {
        Gain input_gain;
        gain => input_gain.gain;
        l => input_gain => loop => r;
    }

    fun void start() {
        if (recording) { return ; }
        this._add_voice();
        loop.playPos(voice, loop.recPos());
        // loop.recPos(loop.playPos(voice));
        loop.rate(voice, 1);
        // Don't play previous buffer contents while recording????
        loop.play(voice, 1);
        loop.loop(voice, 1);
        // loop.voiceGain(voice, 12.0);
        max_record_duration => real_duration;
        now => start_time;
        loop.playPos(voice) => start_pos;
        <<<"Start time: ", start_time >>>;
        <<<"Voice: ", voice >>>;
        1 => recording;
        loop.record(1);
    }

    fun void stop() {
        if (!recording) {return;}
        0 => recording;
        now - start_time => real_duration;
        <<< "Real duration: " , real_duration >>>;
        loop.loopEnd(voice, loop.playPos(voice));
        loop.loopStart(voice, start_pos);
        loop.record(0);
    }

    fun void start_stop() {
        if (recording) {
            this.stop();
        } else {
            this.start();
        }
    }

    fun void delete_loop() {
        this.stop();
        <<<"Deleting loop", voice>>>;
        loop.loop(voice, 0);
        loop.play(voice, 0);
        voice--;
    }
}

