exp.Window.OpenTexture('test');
exp.Show.Rectangle('blue',3,'window','test');
exp.Show.Texture('test')
exp.Window.Flip;
[h,sz,rect,szva] = exp.Window.Get('main')
exp.Show.Texture('test',[],[],1.3*szva);
exp.Window.Flip
exp.Show.Texture('test',[],[],0.9*szva);
exp.Window.Flip
exp.Show.Texture('test',[],[],szva);
exp.Window.Flip