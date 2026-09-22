// Show stats and the mini visualizer?
// var DEBUG = true;
var DEBUG = false;

// Start with mic by default? 
var USEMIC = true;

var sound;
var volume, sensitivity;

var useMic = function () {
    volume = 0;
    sensitivity = 1;
    sound.setVolume(volume);
    sound.setSesitivity(sensitivity);
    sound.connectMic();
}

var useTrack = function () {
    volume = 1;
    sensitivity = 1;
    sound.setVolume(volume);
    sound.setSesitivity(sensitivity);
    sound.connectTrack('assets/spy.mp3');
}

var onSoundInitiated = function () {
    if (USEMIC) {
        useMic();
    } else {
        useTrack();
    }

    loop();
}

sound = new SoundAnalyser(onSoundInitiated);

var debugViz = new SoundVisualizer(document.querySelector('#viz-canvas'), 128, 64);


var stats = new Stats();
stats.domElement.setAttribute('class', 'stats');
if (DEBUG) document.body.appendChild(stats.domElement);

var engine = new SQR.SquarerootGL(document.getElementById('gl-canvas'));
var target = engine.createFrameBuffer();
var projection = new SQR.ProjectionMatrix();
var root = new SQR.Transform();
var camera = new SQR.Transform();
root.add(camera);

var resetCamera = function () {
    camera.position.set(0, 0, 100);
    camera.rotation.set(0, 0, 0);
    camera.lookAt(null);
}

resetCamera();

var resize = () => {
    projection.perspective(45, window.innerWidth / window.innerHeight, 1, 10000);
    engine.setProjection(projection);
    engine.setSize(window.innerWidth, window.innerHeight);
};
// window.addEventListener("resize", resize);
resize();

// Key.down("Q", function () {
//     volume += 0.1;
//     sound.setVolume(volume);
//     console.log(volume, sensitivity);
// });

// Key.down("A", function () {
//     volume -= 0.1;
//     sound.setVolume(volume);
//     console.log(volume, sensitivity);
// });

// Key.down("P", function () {
//     sensitivity += 0.1;
//     sound.setSesitivity(sensitivity);
//     console.log(volume, sensitivity);
// });

// Key.down("L", function () {
//     sensitivity -= 0.1;
//     sound.setSesitivity(sensitivity);
//     console.log(volume, sensitivity);
// });

var leap = new LeapWrapper();

var visualizer = new VisualizerCollection(root);
visualizer.add('gems', new Gems(engine));
visualizer.add('linesphere', new LineSphere(engine));
visualizer.add('strechcube', new StrechingCube(engine));
visualizer.add('skyscraper', new SkyscraperLane(engine));
visualizer.add('pyramids', new Pyramids(engine));
visualizer.add('tunnel', new ShaderVisual(engine, 'glsl/NeonTunnel.glsl'));
visualizer.add('aurora', new ShaderVisual(engine, 'glsl/Aurora.glsl', { speed: 0.8 }));
visualizer.add('kaleido', new ShaderVisual(engine, 'glsl/Kaleidoscope.glsl'));
visualizer.add('outrun', new ShaderVisual(engine, 'glsl/Outrun.glsl'));
visualizer.add('hyperspace', new ShaderVisual(engine, 'glsl/Hyperspace.glsl'));

//
var effect = new EffectCollection();
// effect.add('dof', new DepthOfField(engine));
effect.add('vignette', new Vignette(engine));
effect.add('glow', new GlowChromaticDist(engine));
effect.add('scanlines', new ScanLines(engine));
effect.add('blur', new Blur(engine));
effect.add('none', new NoEffect(engine));

var compositions = [
    ['gems', 'vignette'],
    ['skyscraper', 'glow'],
    ['linesphere', 'blur'],
    ['pyramids', 'none'],
    ['strechcube', 'scanlines'],
    ['tunnel', 'glow'],
    ['aurora', 'none'],
    ['kaleido', 'vignette'],
    ['outrun', 'vignette'],
    ['hyperspace', 'glow']
];

var setEffect = function (index) {
    resetCamera();
    visualizer.use(compositions[index][0], camera, leap);
    effect.use(compositions[index][1]);
}


Menu.onStart(sound.start);
Menu.onEffect(setEffect);
Menu.onMic(useMic);
Menu.onTrack(useTrack);

sound.onBeat = function () {
    if (DEBUG) debugViz.onBeat();
    visualizer.onBeat(camera);
    effect.onBeat();
}

var loop = function () {
    stats.begin();
    requestAnimationFrame(loop);

    SQR.Time.tick();
    leap.tick();

    sound.update();
    if (DEBUG) debugViz.draw(sound);
    visualizer.update(sound, camera, leap);

    engine.render(root, camera, { target: target });
    effect.render(target, root, camera, leap);

    stats.end();

}

setEffect(1);