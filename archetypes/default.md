+++
date = '{{ .Date }}'
draft = true
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
description = ''
subtitle = ''
keywords = ''
thumbnail = '/images/episodes/default.jpg'
audio = ''
audio_length = 0
audio_type = 'audio/mpeg'
audio_duration = '00:00:00'
author = ''
contributors = []
# contributors:
#   - name: "名前"
#     uri: "https://example.com/profile"
season = 1
episode_type = 'full' # full, trailer, bonus
transcript = '' # 文字起こしのURL
+++
