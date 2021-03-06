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
    fun void init() {}
}

class JustLiSa extends Recorder {
    LiSa lisa;
    left => lisa => right;
    time start_time;
    dur start_pos;
    dur duration;
    dur real_duration;
    0 => int recording; // bool
    int voice;
    0 => int buffer_set; // bool

    fun void buffer_default() {
        if (buffer_set) {return;}
        set_buffer(15::second);
    }

    fun void set_loop_start(dur start) {
        start => lisa.loopStart;
    }

    fun void set_duration(dur new_duration) {
        new_duration => duration;
        lisa.loopEnd(voice, start_pos + new_duration);
    }

    fun void record_on() {
        if (recording) {return;}
        buffer_default();
        1 => recording;
        lisa.recPos() => start_pos;
        lisa.loopStart(voice, start_pos);
        // recorder.recPos(recorder.playPos(voice));
        // recorder.rate(voice, 1);
        max_record_duration => duration;
        now => start_time;
        <<<"Start time: ", start_time >>>;
        lisa.record(1);
    }

    fun void record_off() {
        if (!recording) {return;}
        lisa.record(0);
        now - start_time => real_duration;
        set_duration(real_duration);
        lisa.playPos(voice, start_pos);
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
        set_buffer(buffer, 0::ms);
    }
    fun void set_buffer(dur buffer, dur delay) {
        buffer => lisa.duration;
        delay => now;
        0::ms => lisa.recRamp;
        15::second => lisa.duration;
        lisa.getVoice() => voice;
        lisa.feedback(0.0);
        1.0 => lisa.gain;
        lisa.loop(voice, 1);
        1 => buffer_set;
    }
}

class InfiLiSa extends Recorder {
    JustLiSa used_recorders[0];
    JustLiSa @ current_recorder;
    Shred @ record_monitor;
    Shred @ play_monitor;
    5::second => dur CHUNK_SIZE;
    time start_time;
    time last_record_start;
    dur real_duration;
    dur duration;
    0 => int recording; // bool
    8::ms => dur buffer;
    
    fun void _change_recorder() {
        <<<"I", "CHANGE">>>;
        if (current_recorder != null) {
            used_recorders.size() + 1 => used_recorders.size;
            current_recorder @=> used_recorders[used_recorders.size()-1];
            current_recorder.record_off();
            current_recorder.play_off();
            current_recorder.real_duration => dur this_duration;
            <<<"THIS:", this_duration>>>;
            current_recorder.set_duration(current_recorder.real_duration);
        }
        _new_recorder() @=> current_recorder;
        now => last_record_start;
        current_recorder.record_on();
    }

    JustLiSa @ _preallocated;
    0 => int _preallocating;
    fun void preallocator() {
        if (_preallocating) { return; }
        1 => _preallocating;
        2::buffer => now;
        <<<"I", "NEW_REC", "PREALLOC", "GENERATE", "1">>>;
        1::samp => now;
        buffer => now;
        <<<"I", "NEW_REC", "PREALLOC", "GENERATE", "2">>>;
        if (_preallocated != null) {return ;}
        buffer => now;
        <<<"I", "NEW_REC", "PREALLOC", "GENERATE", "3">>>;
        20::buffer => now;
        new JustLiSa @=> _preallocated;
        30::buffer => now;
        <<<"I", "NEW_REC", "PREALLOC", "GENERATE", "4">>>;
        _preallocated.set_buffer(CHUNK_SIZE, buffer);
        buffer => now;
        <<<"I", "NEW_REC", "PREALLOC", "GENERATE", "5">>>;
        // _preallocated.connect(left, right);
        buffer => now;
        <<<"I", "NEW_REC", "PREALLOC", "GENERATED">>>;
        0 => _preallocating;
    }

    fun void init() {
        spork ~ this.preallocator();
        1::second => now;
    }

    fun JustLiSa _new_recorder() {
        JustLiSa @ lisa;
        if (false && _preallocated != null && ! _preallocating) {
            _preallocated @=> lisa;
            _preallocated.connect(left, right);
            <<<"I", "NEW_REC", "PREALLOC", "RETURN">>>;
            null @=> _preallocated;
        } else {
            <<<"I", "NEW_REC", "PREALLOC", "CREATE">>>;
            new JustLiSa @=> lisa;
            lisa.set_buffer(1.1::CHUNK_SIZE);
            lisa.connect(left, right);
        }
        spork ~ preallocator();
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
        current_recorder.play_on();
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
        // record_monitor.exit();
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
        Machine.remove(record_monitor.id());
        Machine.remove(play_monitor.id());
    }
}

class LoopTrack extends CGen {
    Recorder @ recorder;
    // new JustLiSa @=> recorder;
    new InfiLiSa @=> recorder;
    recorder.connect(left, right);
    recorder.init();
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
    0 => int paused;
    0 => int loop_count;
    0::ms => dur duration;

    fun void record_off() {
        if (recording) {
            loops[loop_count-1].record_off();
            0 => recording;
        }
    }

    fun void pause_on() {
        0.0 => right.gain;
        1 => paused;
    }

    fun void pause_off() {
        1.0 => right.gain;
        0 => paused;
    }

    fun void pause_toggle() {
        if (paused) {
            pause_off();
        } else {
            pause_on();
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
        pause_off();
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

    fun void pause(int loop) {
        loops[loop].pause_toggle();
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


////////////////////////////////
// Controller logic

int char;
LooperPedal looper;
adc => Gain input;
120.0 => input.gain;
looper.connect(input, dac);
0 => int selected_loop;
// adc => Gain playthrough_volume => dac;
// 01.0 => playthrough_volume.gain;



class OscListener {
  function void listenOnOsc(string msg, int port) {
    OscRecv recv;
    port => recv.port;

    recv.listen();
    recv.event(msg) @=> OscEvent event;

    while (true) {
      event => now;
      while (event.nextMsg()) { receiveEvent(event); }
    }
  }

  function void receiveEvent(OscEvent event) {}
}

class ListenRecording extends OscListener {
  function void receiveEvent(OscEvent event) {
    event.getInt() => int loop;
    if (loop == -1) {
        return;
    } else {
        looper.start_stop(loop - 1);
    }
  }
}

class ListenDelete extends OscListener {
  function void receiveEvent(OscEvent event) {
    event.getInt() => int loop;
    if (loop == -1) {
        looper.clear();
    } else {
        looper.delete_last(loop - 1);
    }
  }
}

class ListenPause extends OscListener {
  function void receiveEvent(OscEvent event) {
    event.getInt() => int loop;
    if (loop == -1) {
        return;
    } else {
        looper.pause(loop - 1);
    }
  }
}


ListenRecording listenRecording;
ListenDelete listenDelete;
ListenPause listenPause;

spork ~ listenRecording.listenOnOsc("/recording, i", 3000);
spork ~ listenDelete.listenOnOsc("/delete, i", 3000);
spork ~ listenPause.listenOnOsc("/pause, i", 3000);


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


