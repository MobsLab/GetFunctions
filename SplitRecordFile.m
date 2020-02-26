%SplitRecordFile
% See RefSubtraction_multi


function SplitRecordFile(filename,nChannels, name1, Channels1, name2, Channels2)
%channels in neuroscope language
    RefSubtraction_multi(filename,nChannels,2,name1,[],[],Channels1,name2,[],[],Channels2)
end