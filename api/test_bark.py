

from bark import SAMPLE_RATE, generate_audio, preload_models
from scipy.io.wavfile import write as write_wav
from IPython.display import Audio

# download and load all models
preload_models()

# generate audio from text
text_prompt = """
     Hello, my name is Suno. And, uh — and I like pizza. [laughs] 
     But I also have other interests such as playing tic tac toe.
"""
text_prompt2 = """
     在吗，我今天听到一个超好笑的笑话[笑] [laughs] 
     说是一个人去买了一只鹦鹉，回家后鹦鹉就一直在说“你好，我叫小明，我喜欢吃披萨，我还喜欢玩井字棋。”
"""
audio_array = generate_audio(text_prompt2, history_prompt="v2/zh_speaker_6")

# save audio to disk
write_wav("bark_generation2.wav", SAMPLE_RATE, audio_array)
  
# play text in notebook
Audio(audio_array, rate=SAMPLE_RATE)