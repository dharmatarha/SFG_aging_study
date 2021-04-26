function setUpKeyRestrictions(keys)
    % restrict keys to the ones we use
    keysFields = fieldnames(keys);
    keysVector = zeros(1, length(keysFields));
    for f = 1:length(keysFields)
        keysVector(f) = keys.(keysFields{f});
    end
    RestrictKeysForKbCheck(keysVector);
end