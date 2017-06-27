import mingus.core.chords as Chords
import mingus.core.keys as Keys
from mingus.containers import Bar
from mingus.containers import Track
from mingus.containers import NoteContainer
from mingus.containers import Note
from mingus.containers.instrument import MidiInstrument
from mingus.midi import midi_file_out

from mido.midifiles import MidiTrack
import pdb
# chords = [['Ab', 1]]

chords = [  ['Ab', 4.0/3], ['Adim', 4.0/1], ['Eb7', 4.0/4], ['Ab', 4.0/3], ['Adim', 4.0/1], ['Eb7', 4.0/4],
            ['E', 4.0/2], ['Eb', 4.0/2], ['E', 4.0/2], ['Eb', 4.0/2], ['Abm', 4.0/4], ['Abm', 4.0/4],
            ['Ddim', 4.0/4], ['Ab', 4.0/4], ['E', 4.0/2], ['Ab', 4.0/2], ['Ab', 4.0/1], ['Eb7', 4.0/1], ['Ab', 4.0/2],
            ['Ddim', 4.0/4], ['Ab', 4.0/4], ['E', 4.0/2], ['Ab', 4.0/2], ['Ab', 4.0/1], ['Eb7', 4.0/1], ['Ab', 4.0/2]
        ]

track = Track(MidiInstrument())

bar = Bar('Ab', (4,4))
for chordObject in chords:
    chord = NoteContainer().from_chord_shorthand(chordObject[0])
    key = NoteContainer()
    key += Keys.get_notes(chord[0].name)
    chordNotes = NoteContainer()
    keyNotes = NoteContainer()
    # pdb.set_trace()
    for i in range(-3, 4):
        for note in chord:
            chordNotes += Note(int(note)+i*12)
            velocity = 2
            if i==0:
                velocity = 40
        	chordNotes[-1].dynamics = {'velocity': velocity}
        for note in key:
        	keyNotes += Note(int(note)+i*12)
        	keyNotes[-1].dynamics = {'velocity': 1}
    duration = chordObject[1]
    bar.place_notes(chordNotes + keyNotes, duration)
    print bar.current_beat
    if bar.current_beat == 1.0:
        track.add_bar(bar)
        bar = Bar('Ab', (4,4))


midi_file_out.write_Track('test.mid', track)

# with MidiFile() as mid:
#     track = MidiTrack()
#     tracks.append(track)
#
#     tracks.append(midi.Message('program_change', program=12, time=0))
#     tracks.append(midi.Message('note_on', note=64, velocity=64, time=32)
#     tracks.append(midi.Message('note_off', note=64, velocity=127, time=32)
#
#     mid.save('MapleLeafRag.mid')
