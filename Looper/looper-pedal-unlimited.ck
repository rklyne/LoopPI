KBHit kb;
60::second => dur max_record_duration;

fun dur min(dur a, dur b) {
    if (a < b) {
        return a;
    } else {
        return b;
    }
}
fun dur max(dur a, dur b) {
    if (a < b) {
        return b;
    } else {
        return a;
    }
}

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

class Recorder extends CGen {
    fun void record_on() {}
    fun void record_off() {}
    fun void play_on() {}
    fun void play_off() {}
    fun void set_duration(dur duration) {}
    fun void wipe() {}
}

class JustLiSa extends Recorder {
    LiSa lisa;
    left => lisa => right;
    0::ms => lisa.recRamp;
    5::second => lisa.duration;
    lisa.getVoice() => int voice;
    lisa.feedback(0.0);
    1.0 => lisa.gain;
    time start_time;
    dur start_pos;
    dur duration;
    dur real_duration;
    0 => int recording; // bool
    lisa.loop(voice, 1);

    fun void set_loop_start(dur start) {
        start => lisa.loopStart;
    }

    fun void set_duration(dur duration) {
        lisa.loopStart(voice, start_pos);
        lisa.loopEnd(voice, start_pos + duration);
    }

    fun void record_on() {
        if (recording) {return;}
        1 => recording;
        lisa.playPos(voice, lisa.recPos());
        // recorder.recPos(recorder.playPos(voice));
        // recorder.rate(voice, 1);
        // Don't play previous buffer contents while recording????
        max_record_duration => duration;
        now => start_time;
        lisa.playPos(voice) => start_pos;
        <<<"Start time: ", start_time >>>;
        lisa.record(1);
    }

    fun void record_off() {
        if (!recording) {return;}
        lisa.record(0);
        now - start_time => real_duration;
        set_duration(real_duration);
    }

    fun void play_on() {
        lisa.play(1);
    }

    fun void play_off() {
        lisa.play(0);
    }

    fun void wipe() {
        play_off();
        record_off();
        lisa.clear();
    }

    fun void set_buffer(dur buffer) {
        buffer => lisa.duration;
    }
}

class InfiLiSa extends Recorder {
    JustLiSa used_recorders[0];
    JustLiSa @ current_recorder;
    Shred @ record_monitor;
    Shred @ play_monitor;
    4::second => dur CHUNK_SIZE;
    time start_time;
    time last_record_start;
    dur real_duration;
    dur duration;
    0 => int recording; // bool
    
    fun void _change_recorder() {
        me.yield();
        <<<"I", "CHANGE">>>;
        me.yield();
        if (current_recorder != null) {
            used_recorders.size() + 1 => used_recorders.size;
            current_recorder @=> used_recorders[used_recorders.size()-1];
            current_recorder.record_off();
            current_recorder.set_duration(now - last_record_start);
        }
        me.yield();
        _new_recorder() @=> current_recorder;
        now => last_record_start;
        current_recorder.record_on();
        me.yield();
    }

    fun JustLiSa _new_recorder() {
        JustLiSa lisa;
        lisa.set_buffer(1.1::CHUNK_SIZE);
        lisa.connect(left, right);
        return lisa;
    }

    fun void run_record_monitor(dur delay) {
        while (recording) {
            0.9::delay => now;
            if (recording) {
                <<<"I", "RRM CHANGE">>>;
                this._change_recorder();
            }
        }
    }

    fun void run_play_monitor() {
        dur remaining;
        dur wait_time;
        int i;
        // TODO: Should I wait extra_time first? 
        // It will be happening at the _end_ of the recording.
        me.yield();
        duration - real_duration => wait_time;
        (start_time % duration) - (now % duration) => wait_time;
        if (wait_time >= duration) {
            <<<"I", "Multi Play", "SKIPPED", "Pre-Wait", wait_time>>>;
        } else if (wait_time > 0::second) {
            <<<"I", "Multi Play", "Extra", "Pre-Wait", wait_time>>>;
            wait_time => now;
        }
        while (1) {
            duration => remaining;

            for (0 => i; i < used_recorders.size(); i++) {
                <<<"I", "Multi Play", i, "remaining", remaining>>>;
                used_recorders[i].play_on();
                min(remaining, used_recorders[i].real_duration) => wait_time;
                wait_time => now;
                remaining - wait_time => remaining;
                used_recorders[i].play_off();
            }
            if (remaining > 0::second) {
                <<<"I", "Multi Play", "Extra", "remaining", remaining>>>;
                remaining => now;
            }
            <<<"I", "Multi Play", "Re-Start", "mod", now % duration, start_time % duration>>>;
        }
    }

    fun void record_on() {
        if (recording) {return;}
        1 => recording;
        <<<"I", "REC ON">>>;
        now => start_time;
        this._change_recorder();
        current_recorder.record_on();
        spork ~ run_record_monitor(CHUNK_SIZE) @=> record_monitor;
    }
    
    fun void record_off() {
        <<<"I", "REC Off 1">>>;
        if (!recording) {return;}
        <<<"I", "REC Off 2">>>;
        0 => recording;
        <<<"I", "REC Off 3">>>;
        _change_recorder();
        <<<"I", "REC Off 4">>>;
        current_recorder.record_off();
        record_monitor.exit();
        Machine.remove(record_monitor.id());
        spork ~ run_play_monitor() @=> play_monitor;
    }

    fun void play_off() {
        0.0 => this.right.gain;
    }

    fun void play_on() {
        1.0 => this.right.gain;
    }

    fun void set_duration(dur new_duration) {
        new_duration => duration;
    }

    fun void wipe() {
        for (0 => int i; i < used_recorders.size(); i++) {
            used_recorders[i].wipe();
            used_recorders[i].disconnect();
        }
        0 => used_recorders.size;
        Machine.remove(play_monitor.id());
    }
}

class LoopTrack extends CGen {
    Recorder @ recorder;
    new JustLiSa @=> recorder;
    new InfiLiSa @=> recorder;
    recorder.connect(left, right);
    int recording;
    dur real_duration;
    dur duration;
    time start_time;

    fun void set_play_duration(dur playback) {
        // TODO: Complete this bit!
        playback => duration;
        recorder.set_duration(duration);
        <<< "Play duration: " , duration >>>;
    }

    fun void record_off() {
        if (!recording) {return ;}
        0 => recording;
        now - start_time => real_duration;
        real_duration => duration;
        <<< "Real duration: " , real_duration >>>;
        this.set_play_duration(duration);
        recorder.record_off();
    }

    fun void record_on() {
        if (recording) { return ; }
        recorder.play_on();
        recorder.record_on();
        1 => recording;
        now => start_time;
    }

    fun void stop() {
        recorder.play_off();
        recorder.record_off();
        recorder.wipe();
        recorder.disconnect();
        new Recorder @=> recorder;
    }
}


class MultitrackLoop extends CGen {
    20 => int max_loops;
    LoopTrack @ loops[max_loops];
    0 => int recording;
    0 => int loop_count;
    0::ms => dur duration;

    fun void record_off() {
        if (recording) {
            loops[loop_count-1].record_off();
            0 => recording;
        }
    }

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
        this.record_off();
        if (loop_count == 0) {return ;}
        loop_count--;
        loops[loop_count].stop();
        loops[loop_count].disconnect();
        if (loop_count == 0) {
            0::ms => duration;
        }
    }

    fun void remove_all() {
        this.record_off();
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

    fun void stop_recording_all_except(int loop) {
        for (0 => int i; i < num_loops; i++) {
            if (i != loop) {
                loops[i].record_off();
            }
        }
        // this.update_duration();
    }

    fun void start_stop(int loop) {
        this.stop_recording_all_except(loop);
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
1 => int running;
while (running) {
  kb => now;

  while (kb.more()) {
    kb.getchar() => char;
    if (char == 32) { // space
        looper.start_stop(selected_loop);
    } else if (char == 127) { // backspace
        looper.delete_last(selected_loop);
    } else if (char == 49) { // "1"
        0 => selected_loop;
    } else if (char == 50) { // "2"
        1 => selected_loop;
    } else if (char == 51) { // "3"
        2 => selected_loop;
    } else if (char == 52) { // "4"
        3 => selected_loop;
    } else if (char == 100) { // "d"
        looper.disconnect();
    } else if (char == 113) { // "q"
        0 => running;
        <<<"Quitting">>>;
    } else if (char == 114) { // "r"
        looper.disconnect();
        1::samp => now;
        looper.connect(adc, dac);
    } else {
        <<<"Unhandled key: ", char >>>;
    }
    <<<"Using loop ", selected_loop >>>;

  }
}


