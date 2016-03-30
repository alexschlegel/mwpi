seed = 58789;
d = 0.0830;

generator = cell(300,1);
for i = 1:300
	generator{i} = stimulus.image.blob.spike('d', d, 'seed', seed, 'size', i);
end

figures = cellfun(@(gen) gen.generate, generator, 'uni', false);
correctFigure = find(cellfun(@(fig) all(fig(1,end,:) == cat(3,0.5,0.5,0.5)), figures));