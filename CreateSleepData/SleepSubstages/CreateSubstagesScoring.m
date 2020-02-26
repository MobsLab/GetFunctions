%CreateSubstagesScoring

[featuresNREM, Namesfeatures, EpochSleep, NoiseEpoch, scoring] = FindNREMfeatures('scoring','ob');
save('FeaturesScoring', 'featuresNREM', 'Namesfeatures', 'EpochSleep', 'NoiseEpoch', 'scoring')
[Epoch, NameEpoch] = SubstagesScoring(featuresNREM, NoiseEpoch,'verbose',0);
save('SleepSubstages', 'Epoch', 'NameEpoch')
                    
                    