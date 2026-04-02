# based on https://github.com/recoilme/deforum_music

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import numpy as np
import os, json
from scipy.io import wavfile
from scipy.signal import butter, filtfilt, find_peaks
import matplotlib.pyplot as plt
from pydub import AudioSegment
import argparse

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
    desc = "Blah"
    parser = argparse.ArgumentParser()
    parser.add_argument("--music", type=str, help="MP3 or WAV file")
    parser.add_argument("--fps", type=int, help="FPS")
    
    args = parser.parse_args()
    return args

args2=parse_args();



frequency_ranges = {
    'Low Frequencies': (0, 250),
    'Mid Frequencies': (250, 2000),
    'High Frequencies': (2000, 20000),
}

seconds_to_analyze = 0 # 0 - All
frames_per_second = args2.fps
filename = args2.music
deforum_settings_base = '_deforum_music_settings.txt'
deforum_settings_result = 'deforum_music_settings.txt'
# (min, max, cadence)
translation_koef = 2
translation_x = (-1.4*translation_koef,1.4*translation_koef, 3) # (-1.4,1.4,3)
translation_y = (-1.4*translation_koef,1.4*translation_koef, 3) # (-1.4,1.4,3)
# speed
translation_z = (-1.4*translation_koef,1.4*translation_koef, 3)

rotation_koef = 1
rotation_3d_x = (-0.4*rotation_koef,0.4*rotation_koef, 6) # (-0.4,0.4,6)
rotation_3d_y = (-0.4*rotation_koef,0.4*rotation_koef, 6) # (-0.4,0.4,6)

cfg_scale_schedule = (5,15, 1) # (5,15, 1)
strength_schedule = (0.45,0.65,1) # (0.45,0.65,1)
peaks_koef = 0.75

human_hearing_min = 20  # Минимальная слышимая частота в Гц
human_hearing_max = 20000  # Максимальная слышимая частота в Гц

# Чтение  файла
def read_audio_file(filename):
    # Определяем расширение файла
    _, file_extension = os.path.splitext(filename)

    if file_extension.lower() == '.mp3':
        # Загрузка MP3 файла
        audio = AudioSegment.from_file(filename, format="mp3")
        
        # Преобразование аудио в массив numpy
        audio_data = np.array(audio.get_array_of_samples())

        # Переделываем стерео в моно при необходимости
        if audio.channels > 1:
            audio_data = audio_data.reshape((-1, audio.channels))
            audio_data = audio_data.mean(axis=1).astype(np.int16)

        sample_rate = audio.frame_rate
        
    elif file_extension.lower() == '.wav':
        # Чтение WAV файла
        sample_rate, audio_data = wavfile.read(filename)
        if audio_data.ndim > 1:
            audio_data = np.mean(audio_data, axis=1)

    else:
        raise ValueError("Unsupported file format")

    return sample_rate, audio_data

sample_rate, audio_data = read_audio_file(filename)

# Функция для полосового фильтра
def bandpass_filter(data, lowcut, highcut, sample_rate, order=5):
    nyquist = 0.5 * sample_rate
    low = lowcut / nyquist
    high = highcut / nyquist
    b, a = butter(order, [low, high], btype='band')
    y = filtfilt(b, a, data)
    return y

# Применяем фильтр ко всему диапазону длины файла
filtered_audio_data = bandpass_filter(audio_data, human_hearing_min, human_hearing_max, sample_rate)

if seconds_to_analyze>0:
    audio_data = filtered_audio_data[:sample_rate * seconds_to_analyze]
else:
    audio_data = filtered_audio_data

# Функция для расчета средних амплитуд для заданных диапазонов
def get_amplitude_by_range(frame_data, sample_rate, freq_range):
    n = len(frame_data)
    fft_result = np.fft.rfft(frame_data)
    fft_freqs = np.fft.rfftfreq(n, 1 / sample_rate)

    amplitudes = np.abs(fft_result)

    mask = (fft_freqs >= freq_range[0]) & (fft_freqs <= freq_range[1])
    data = np.abs(amplitudes[mask])
    return data

# Функция нормализации 
def normalize(data, min_value=0, max_value=1, window_size=1, inverted = False):
    # Обрезаем выбросы, превышающие 3 стандартных отклонения
    data_mean = np.mean(data)
    data_std = np.std(data)
    data = np.clip(data, data_mean - 3 * data_std, data_mean + 3 * data_std)
    if window_size>1:
        # Паддинг - дополнение массива справа (или слева) дубликатами крайних значений
        padding = np.repeat(data[-1], window_size - 1)
        extended_array = np.concatenate((data, padding))
    
        cumsum_vec = np.cumsum(np.insert(extended_array, 0, 0)) 
        smoothed_array = (cumsum_vec[window_size:] - cumsum_vec[:-window_size]) / window_size
    
        # Обрезка массива до исходной длины
        data = smoothed_array[:len(data)]

    # Минимальное и максимальное значения для корректной нормализации
    array_min, array_max = np.min(data), np.max(data)

    # Если минимальное и максимальное значения равны, используем min_value
    if array_min == array_max:
        normalized_array = np.ones_like(data) * min_value
    else:
        # В противном случае выполняем нормализацию
        normalized_array = (data - array_min) / (array_max - array_min)
        normalized_array = normalized_array * (max_value - min_value) + min_value
    
    if inverted:
        normalized_array = max_value - (normalized_array - min_value)
    return normalized_array

# Подготовка массива для амплитуд по частотным диапазонам
samples_per_frame = sample_rate // frames_per_second
amplitudes = {range_name: [] for range_name in frequency_ranges}

# Анализ амплитуд по частотным диапазонам
# Итерируем по аудиоданным с шагом в samples_per_frame семплов
for start in range(0, len(audio_data), samples_per_frame):
    end = start + samples_per_frame
    # Если мы на последнем сегменте и он не полный
    if end > len(audio_data):
        end = len(audio_data)  # Укорачиваем последний сегмент до конца массива
    frame_data = audio_data[start:end]
    for range_name, freq_range in frequency_ranges.items():
        amplitudes[range_name].append(
            np.mean(get_amplitude_by_range(frame_data, sample_rate, freq_range)))


# Отображение данных с нормализацией и сглаживанием
for range_name in frequency_ranges:
    norm_array = normalize(np.array(amplitudes[range_name]),-1,2,3)
    formatted_string = ", ".join(f"{index}: ({value:.2f})" for index, value in enumerate(norm_array))
    #print(formatted_string)
 
    plt.figure(figsize=(12, 4))
    plt.plot(norm_array, label=range_name)
    plt.title(f"Average Amplitude of {range_name}")
    plt.xlabel("Frame")
    plt.ylabel("Normalized Amplitude")
    plt.legend()
    plt.tight_layout()
    #plt.show()

all_peaks = []
for range_name in frequency_ranges:
    norm_array = normalize(np.array(amplitudes[range_name]),-1,1,3)
    peaks, _ = find_peaks(np.abs(np.diff(np.diff(norm_array))))
    all_peaks.extend((peak, norm_array[peak]) for peak in peaks)

selected_peaks = [0]
max_peaks = (len(audio_data) // sample_rate) // 4

# Сортируем все пики по величине в убывающем порядке
all_peaks.sort(key=lambda x: x[1], reverse=True)
for peak, value in all_peaks:
    if not selected_peaks:
        # Если ещё нет выбранных пиков, просто добавляем первый пик
        selected_peaks.append(peak)
    else:
        # Проверяем расстояние от текущего пика до всех уже выбранных пиков
        if all(abs(peak - selected_peak) >= frames_per_second*10 for selected_peak in selected_peaks):
            selected_peaks.append(peak)
    # Если мы достигли нужного количества пиков, прерываем цикл
    if len(selected_peaks) == max_peaks:
        break
selected_peaks.sort()
numbers_dict = {str(number): "" for number in selected_peaks}
numbers_json = json.dumps(numbers_dict, indent=4)
#print('prompt:')
#print(numbers_json)

def deforum_str(array):
    return ",".join(f"{index}:{value:.2f}" for index, value in enumerate(array))
    
# Чтение JSON из файла
#with open(deforum_settings_base, 'r', encoding='utf-8') as f:
#    deforum = json.load(f)
#for key, value in deforum.items():
#    print(f"The value of field '{key}' ")
#deforum['soundtrack_path']=filename

if os.path.isfile('results.txt'):
    os.remove('results.txt')

file1 = open("results.txt","a")

for range_name in frequency_ranges:
    if range_name == 'Low Frequencies':
        print(f"Max frames = {len(np.array(amplitudes[range_name]))}")
        file1.write(str(len(np.array(amplitudes[range_name])))+'\n')
        #rotation based on low frequencies
        print(f"Rotation = {deforum_str(normalize(np.array(amplitudes[range_name]),translation_z[0],translation_z[1],translation_z[2]))}")
        file1.write(deforum_str(normalize(np.array(amplitudes[range_name]),translation_z[0],translation_z[1],translation_z[2]))+'\n')
        """
        #deforum['max_frames']=len(np.array(amplitudes[range_name]))
        #print("cfg:")
        #print(deforum_str(normalize(np.array(amplitudes[range_name]),6,16,1)))
        deforum['cfg_scale_schedule'] = deforum_str(normalize(np.array(amplitudes[range_name]),cfg_scale_schedule[0],cfg_scale_schedule[1],cfg_scale_schedule[2]))
        #print("str:")
        x = normalize(np.array(amplitudes[range_name]),strength_schedule[0],strength_schedule[1],strength_schedule[2],True)
        x[selected_peaks] *= peaks_koef
        #print(deforum_str(x))
        deforum['strength_schedule'] = deforum_str(x)
        #print("Translation Z:")
        #print(deforum_str(normalize(np.array(amplitudes[range_name]),-1,4,3)))
        deforum['translation_z'] = deforum_str(normalize(np.array(amplitudes[range_name]),translation_z[0],translation_z[1],translation_z[2]))
        """
    if range_name == 'Mid Frequencies':
        #Pan X based on mid frequencies
        data_mean = np.mean(normalize(np.array(amplitudes[range_name]),translation_x[0],translation_x[1],translation_x[2],True))
        print(f"Pan X = {deforum_str(normalize(np.array(amplitudes[range_name]),translation_x[0],(translation_x[1]-data_mean*2),translation_x[2],True))}")
        file1.write(deforum_str(normalize(np.array(amplitudes[range_name]),translation_x[0],(translation_x[1]-data_mean*2),translation_x[2],True))+'\n')
        """
        data_mean = np.mean(normalize(np.array(amplitudes[range_name]),translation_x[0],translation_x[1],translation_x[2],True))
        deforum['translation_x']=deforum_str(normalize(np.array(amplitudes[range_name]),translation_x[0],(translation_x[1]-data_mean*2),translation_x[2],True))
        #print("Rotation 3D Y:")
        data_mean = np.mean(normalize(np.array(amplitudes[range_name]),rotation_3d_y[0],rotation_3d_y[1],rotation_3d_y[2]))
        deforum['rotation_3d_y']=deforum_str(normalize(np.array(amplitudes[range_name]),rotation_3d_y[0],(rotation_3d_y[1]-data_mean*2),rotation_3d_y[2]))
        #print(deforum_str(normalize(np.array(amplitudes[range_name]),-0.4,0.4,3)))
        """
    if range_name == 'High Frequencies':
        #Pan Y based on high frequencies
        data_mean = np.mean(normalize(np.array(amplitudes[range_name]),translation_y[0],translation_y[1],translation_y[2],True))
        print(f"Pan Y = {deforum_str(normalize(np.array(amplitudes[range_name]),translation_y[0],translation_y[1]-data_mean*2,translation_y[2],True))}")
        file1.write(deforum_str(normalize(np.array(amplitudes[range_name]),translation_y[0],translation_y[1]-data_mean*2,translation_y[2],True))+'\n')
        """
        data_mean = np.mean(normalize(np.array(amplitudes[range_name]),translation_y[0],translation_y[1],translation_y[2],True))
        deforum['translation_y']=deforum_str(normalize(np.array(amplitudes[range_name]),translation_y[0],translation_y[1]-data_mean*2,translation_y[2],True))
        
        data_mean = np.mean(normalize(np.array(amplitudes[range_name]),rotation_3d_x[0],rotation_3d_x[1],rotation_3d_x[2]))
        deforum['rotation_3d_x']=deforum_str(normalize(np.array(amplitudes[range_name]),rotation_3d_x[0],(rotation_3d_x[1]-data_mean*2),rotation_3d_x[2]))
        """

file1.close()
"""
# Сохранение файла с обновленным значением поля
try:
    with open(deforum_settings_result, 'w', encoding='utf-8') as ff:
        json.dump(deforum, ff, ensure_ascii=False, indent=4)
    print("Файл успешно обновлен.")
except Exception as e:
    print(f"Произошла ошибка при записи файла: {e}")
"""