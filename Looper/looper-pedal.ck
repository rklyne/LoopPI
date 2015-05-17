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
        right => _right;
    }

    fun void disconnect() {
        _left !=> left;
        right !=> _right;
    }
}

class LoopTrack extends CGen {
    LiSa recorder;
    0::ms => recorder.recRamp;
    recorder.feedback(0.0);
    60::second => dur max_duration;
    max_duration => recorder.duration;
    left => recorder => right;
    int recording;
    dur start_pos;
    dur real_duration;
    dur duration;
    time start_time;
    recorder.getVoice() => int voice;
    1.0 => recorder.gain;

    fun void set_play_duration(dur playback) {
        // TODO: Complete this bit!
        playback => duration;
        recorder.loopStart(voice, start_pos);
        recorder.loopEnd(voice, start_pos + duration);
        <<< "Play duration: " , duration >>>;
    }

    fun void record_off() {
        if (!recording) {return ;}
        0 => recording;
        now - start_time => real_duration;
        real_duration => duration;
        <<< "Real duration: " , real_duration >>>;
        this.set_play_duration(duration);
        recorder.record(0);
    }

    fun void record_on() {
        if (recording) { return ; }
        recorder.play(voice, 1);
        recorder.loop(voice, 1);
        recorder.playPos(voice, recorder.recPos());
        // recorder.recPos(recorder.playPos(voice));
        recorder.rate(voice, 1);
        // Don't play previous buffer contents while recording????
        max_record_duration => duration;
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

fun dur max(dur a, dur b) {
    if (a < b) {
        return b;
    } else {
        return a;
    }
}

class MultitrackLoop extends CGen {
    20 => int max_loops;
    LoopTrack @ loops[max_loops];
    0 => int recording;
    0 => int loop_count;
    0::ms => dur duration;

    fun void record_toggle() {
        if (recording) {
            0 => recording;
            <<<"stopping ", loop_count-1>>>;
            loops[loop_count-1].record_off();
            this.update_duration(loops[loop_count-1].duration);
        } else {
            1 => recording;
            <<<"starting ", loop_count>>>;
            LoopTrack track @=> loops[loop_count];
            track.connect(left, right);
            loop_count++;
            <<<"Track: ", loop_count >>>;
            track.record_on();
        }
    }

    fun void update_duration(dur last_duration) {
        // Longest
        max(last_duration, duration) => duration;
        set_duration(duration);
    }

    fun void set_duration(dur new_duration) {
        for (0 => int i; i < loop_count; i++) {
            (new_duration / loops[i].duration + 0.5) $ int => int repetitions;
            loops[i].set_play_duration(new_duration/repetitions);
        }
        // Maybe try 'pinned-to-first' duration too?
    }

    fun void remove_last() {
        if (loop_count == 0) {return ;}
        loop_count--;
        loops[loop_count].stop();
        loops[loop_count].disconnect();
        if (loop_count == 0) {
            0::ms => duration;
        }
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
    left => right;
    4 => int num_loops;
    MultitrackLoop loops[num_loops];
    for (0 => int i; i < num_loops; i++) {
        loops[i].connect(left, right);
    }

    fun void start_stop(int loop) {
        loops[loop].record_toggle();
        update_duration();
    }

    fun void delete_last(int loop) {
        loops[loop].remove_last();
    }

    fun void update_duration() {
        // Longest
        0::ms => dur duration;
        for (0 => int i; i < num_loops; i++) {
            max(loops[i].duration, duration) => duration;
        }
        <<<"Master duration", duration>>>;
        for (0 => int i; i < num_loops; i++) {
            loops[i].set_duration(duration);
        }
    }

    fun void clear() {
        for (0 => int i; i < num_loops; i++) {
            loops[i].remove_all();
        }
    }
}

int char;
LooperPedal looper;
looper.connect(adc, dac);
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


