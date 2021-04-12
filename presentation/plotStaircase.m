function plotStaircase(subjectNr)
    subjectStr = num2str(subjectNr);
    logFileName = strcat('subject', subjectStr, filesep, 'sub', subjectStr, 'Log.mat');
    load(logFileName, 'logVar');
    yticks(0:1:10);
    logNoHeader = logVar(2:end, :);
    blockNumbers = cell2mat(logNoHeader(:,2));
    blockNumberList = unique(blockNumbers);
    seriesTitles = cell2mat(arrayfun(@(x) sprintf('Block %s', num2str(x)), blockNumberList, 'uniformoutput',false));
    lineWidth = length(blockNumberList);
    for block = blockNumberList'
        blockLog=logNoHeader(blockNumbers == block, :);
        plot(abs(cell2mat(blockLog(:, 7))), 'LineWidth', lineWidth);
        hold on;
        % Decrementing the line width so that overlapping lines stay visible
        lineWidth = lineWidth - 1;
    end
    title(sprintf('SFG learning staircase for subject %s', subjectStr));
    xlabel('Trial');
    ylabel('Step size');
    legend(seriesTitles);
end