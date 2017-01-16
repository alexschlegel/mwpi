from mvpa2.suite import *

class RelabelMapper(Mapper):
	newLabels = None;

	def __init__(self, newlabels):
		Mapper.__init__(self)
		self.newLabels = newlabels

	def forward(self, data):
		"""change label of test sample to corresponding new label"""
		newData = data.copy()
		kChunk = newData.sa.chunks[newData.sa.partitions==2][0]
		# avoid off-by-one error!
		indChunk = kChunk - 1
		newLabel = self.newLabels[indChunk]
		newData.sa.targets[newData.sa.partitions==2] = newLabel
		return newData