
function start_time_epoch = getStartTimeAsEpoch(path)

    video_data = ffmpeginfoVideoSync(path);
    start_time_char = video_data.meta.creation_time;
    start_time_datetime = datetime(start_time_char, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS''Z');
    format longG
    start_time_epoch = posixtime(start_time_datetime);
    
end





