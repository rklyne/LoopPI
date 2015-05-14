KBHit kb;
60::second => dur max_record_duration;

class CGen {
    Gain left;
    Gain right;
    UGen @ _left;
    UGen @ _right;
    1.0 => left.gain;
    1.0 => right.gain;

    fun void connect(UGen l, UGen r) {
        l @=> _left;
        r @=> _right;
        _left => left;
        _right => right;
    }

    fun void disconnect() {
        _left !=> left;
        _right !=> right;
    }
}

class LoopTrack extends CGen {
    LiSa recorder;
    left => recorder => right;
    60::second => dur max_duration;
    dur recording_duration;
    int recording;
    dur start_pos;
    time start_time;
    dur real_duration;
    0 => int voice;

    fun void record_off() {
        if (!recording) {return ;}
        0 => recording;
        now - start_time => real_duration;
        <<< "Real duration: " , real_duration >>>;
        recorder.loopEnd(voice, recorder.playPos(voice));
        recorder.loopStart(voice, start_pos);
        recorder.record(0);
    }

    fun void record_on() {
        if (recording) { return ; }
        recorder.playPos(voice, recorder.recPos());
        // recorder.recPos(recorder.playPos(voice));
        recorder.rate(voice, 1);
        // Don't play previous buffer contents while recording????
        recorder.play(voice, 1);
        recorder.loop(voice, 1);
        max_record_duration => real_duration;
        now => start_time;
        recorder.playPos(voice) => start_pos;
        <<<"Start time: ", start_time >>>;
        1 => recording;
        recorder.record(1);
    }

    fun void stop() {
        recorder.play(0);
        recorder.loop(0);
    }
}

class MultitrackLoop extends CGen {
    20 => int max_loops;
    LoopTrack @ loops[max_loops];
    int recording;
    0 => int loop_count;

    fun void record_toggle() {
        if (recording) {
            0 => recording;
            loops[loop_count-1].record_off();
        } else {
            1 => recording;
            LoopTrack track @=> loops[loop_count];
            loop_count++;
            <<<"Loop: ", loop_count >>>;
            track.record_on();
            track.connect(left, right);
        }
    }

    fun void remove_last() {
        if (loop_count == 0) {return ;}
        loop_count--;
        loops[loop_count].stop();
        loops[loop_count].disconnect();
    }

    fun void remove_all() {
        for (0 => int i; i < loop_count; i++) {
            loops[i].stop();
            loops[i].disconnect();
        }
        0 => loop_count;
    }
}

public class LooperPedal extends CGen {
    4 => int num_loops;
    MultitrackLoop loops[num_loops];

    fun void start_stop(int loop) {
        loops[loop].record_toggle();
    }

    fun void delete_last(int loop) {
        loops[loop].remove_last();
    }

    fun void clear() {
        for (0 => int i; i < num_loops; i++) {
            loops[i].remove_all();
        }
    }
}

class Looper {
    UGen input;
    UGen output;
    dur start_pos;
    time start_time;
    dur real_duration;
    LiSa loop;
    0 => int recording;
    0 => int voice; // current recording voice
    int voice_count;
    max_record_duration => loop.duration;
    // 2.5 => loop.gain;
    loop.feedback(0.0);
    0::ms => loop.recRamp;
    1.0 => float gain;

    fun int _add_voice() {
        voice++;
        return voice;
    }

    fun int _voice() {
        return voice;
    }

    fun void connect( UGen l, UGen r ) {
        l @=> this.input;
        r @=> this.output;
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
        if (voice == 0)
            return;
        this.stop();
        <<<"Deleting loop", voice>>>;
        loop.loop(voice, 0);
        loop.play(voice, 0);
        voice--;
    }
}

int char;
LooperPedal looper;
looper.connect(adc, dac);
adc => dac;
0 => int selected_loop;
// adc => Gain playthrough_volume => dac;
// 01.0 => playthrough_volume.gain;
<<<"Ready">>>;

while (true) {
  kb => now;

  while (kb.more()) {
    kb.getchar() => char;
    if (char == 32) { // space
      looper.start_stop(selected_loop);
    }
    else if (char == 127) { // backspace
        looper.delete_last(selected_loop);
    } else if (char == 49) { // "1"
        0 => selected_loop;
    } else if (char == 50) { // "2"
        1 => selected_loop;
    } else if (char == 51) { // "3"
        2 => selected_loop;
    } else if (char == 52) { // "4"
        3 => selected_loop;
    } else {
        <<<"Unhandled key: ", char >>>;
    }
    <<<"Using loop ", selected_loop >>>;

  }
}


