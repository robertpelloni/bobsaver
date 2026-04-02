#version 420

// original https://www.shadertoy.com/view/ldKBRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Einstein, by mattz.
   License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

   Displaying Albert Einstein using 128 Gabor functions.

   Similar to https://www.shadertoy.com/view/4ljSRR but computed in under 30 min
   using TensorFlow.

   Composition looks a little odd here because the approximation was computed
   on a square domain.

   See https://mzucker.github.io/2018/04/27/image-fitting-tensorflow-rewrite.html

*/

// Hash functions from Dave Hoskins https://www.shadertoy.com/view/4djSRW

#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(.1031, .1030, .0973, .1099)

float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec4 hash41(float p) {
    vec4 p4 = fract(vec4(p) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
    
}

const vec4 scl = vec4(0.00391389432485, 0.0122958616579, 0.00782778864971, 0.00391389432485);

float cnt = 0.0;

float gabor(vec2 p, vec4 q) {
    
    // Here we decode the vec4 q into 8 individual parameters:
    //
    //   q0 = (x, a, l, s)
    //   q1 = (y, p, t, h)
    //
    // with parameters given by
    //
    //   x: function center x coordinate
    //   y: function center y coordinate
    //   a: Gabor function spatial angle/orientation
    //   p: Gabor function phase offset
    //   l: Spatial wavelength
    //   s: Filter width perpendicular to sinusoidal component 
    //   t: Filter width parallel to sinusoidal component
    //   h: Amplitude
    //
    vec4 q0 = floor(q*0.001953125)*scl;
    vec4 q1 = mod(q, 512.0)*scl;     
    
    vec4 rnd = hash41(cnt) * 2.0 - 1.0;
    cnt += 1.0;
    
    float fadein = smoothstep(6.0, 0.0, time);
    
    float theta = q0.y + 3.14*fadein*rnd.z;
    vec2 p0 = 2.*vec2(q0.x, q1.x);
    
    p0 += 4.0 * rnd.xy * fadein;
            
    float cr = cos(theta);
    float sr = sin(theta);
        
    vec2 st = vec2(q0.w, q1.z);

    // Rotate and translate point
    p = mat2(cr, -sr, sr, cr) * (p - p0);    
            
    // Handle appearing at the start of filter
    q1.w *= (1.0 - fadein);

    // amplitude * gaussian * sinusoid
    return q1.w * exp(dot(vec2(-0.5), p*p/(st*st))) * cos(p.x*6.2831853/q0.z+q1.y + 10.0*rnd.w*fadein);
    
}

void main(void) {
        
    vec2 p = (gl_FragCoord.xy - 0.5*resolution.xy) * 1.2 / resolution.y;
    p.y = -p.y;
    p *= 1.3;
    p += vec2(2.25, 2.125);
    
    float k = 0.0;

    k += gabor(p, vec4(124724.,215881.,131766.,131835.));
    k += gabor(p, vec4(157335.,242926.,133491.,50545.));
    k += gabor(p, vec4(79180.,164856.,102511.,45240.));
    k += gabor(p, vec4(128164.,208372.,32295.,14847.));
    k += gabor(p, vec4(161603.,121737.,19480.,16383.));
    k += gabor(p, vec4(112925.,108280.,37965.,10045.));
    k += gabor(p, vec4(116484.,37759.,58372.,4095.));
    k += gabor(p, vec4(117040.,136266.,30216.,2768.));
    k += gabor(p, vec4(149330.,22112.,11275.,7167.));
    k += gabor(p, vec4(97650.,95376.,30225.,3583.));
    k += gabor(p, vec4(16554.,75246.,43600.,43777.));
    k += gabor(p, vec4(104668.,12938.,49778.,50104.));
    k += gabor(p, vec4(151320.,106537.,15905.,4219.));
    k += gabor(p, vec4(145228.,199047.,10767.,7993.));
    k += gabor(p, vec4(132862.,191440.,13414.,12818.));
    k += gabor(p, vec4(144690.,230672.,15915.,16000.));
    k += gabor(p, vec4(92969.,142615.,32272.,10751.));
    k += gabor(p, vec4(172976.,132391.,59222.,54385.));
    k += gabor(p, vec4(148733.,142297.,5643.,5673.));
    k += gabor(p, vec4(131319.,80734.,50192.,5119.));
    k += gabor(p, vec4(79581.,88402.,40249.,40058.));
    k += gabor(p, vec4(142090.,252814.,26121.,5119.));
    k += gabor(p, vec4(97433.,37328.,6685.,5695.));
    k += gabor(p, vec4(118095.,251126.,52442.,28242.));
    k += gabor(p, vec4(156321.,201765.,57349.,3871.));
    k += gabor(p, vec4(93450.,137060.,25094.,3071.));
    k += gabor(p, vec4(95024.,140723.,33291.,11238.));
    k += gabor(p, vec4(171226.,104879.,30763.,9727.));
    k += gabor(p, vec4(95045.,156071.,32272.,4410.));
    k += gabor(p, vec4(157009.,79495.,11317.,11006.));
    k += gabor(p, vec4(153981.,217841.,66573.,4353.));
    k += gabor(p, vec4(167101.,220097.,5127.,2422.));
    k += gabor(p, vec4(104712.,14852.,41267.,40028.));
    k += gabor(p, vec4(133931.,236155.,19502.,9513.));
    k += gabor(p, vec4(164634.,38530.,25765.,21756.));
    k += gabor(p, vec4(154428.,27222.,23571.,7679.));
    k += gabor(p, vec4(150863.,23444.,12820.,6143.));
    k += gabor(p, vec4(197858.,128865.,129789.,45264.));
    k += gabor(p, vec4(148779.,169165.,3586.,2229.));
    k += gabor(p, vec4(165122.,259066.,103437.,7679.));
    k += gabor(p, vec4(159953.,115785.,20002.,7006.));
    k += gabor(p, vec4(117956.,144873.,63076.,53621.));
    k += gabor(p, vec4(88239.,200150.,3077.,2143.));
    k += gabor(p, vec4(122622.,153014.,4615.,2164.));
    k += gabor(p, vec4(166074.,222981.,5636.,3071.));
    k += gabor(p, vec4(153847.,72401.,25607.,7167.));
    k += gabor(p, vec4(126771.,227567.,19498.,14687.));
    k += gabor(p, vec4(123565.,76676.,23072.,20198.));
    k += gabor(p, vec4(101112.,137890.,25112.,8468.));
    k += gabor(p, vec4(149268.,57165.,240426.,38474.));
    k += gabor(p, vec4(188151.,43938.,26805.,23788.));
    k += gabor(p, vec4(130308.,193167.,12808.,2559.));
    k += gabor(p, vec4(133373.,97521.,3589.,3703.));
    k += gabor(p, vec4(153386.,240392.,4102.,2717.));
    k += gabor(p, vec4(145218.,199502.,14867.,14148.));
    k += gabor(p, vec4(106852.,92914.,45618.,45797.));
    k += gabor(p, vec4(152887.,157952.,75786.,5073.));
    k += gabor(p, vec4(114401.,246545.,75287.,5339.));
    k += gabor(p, vec4(177371.,238705.,5657.,4095.));
    k += gabor(p, vec4(103673.,128146.,38408.,4607.));
    k += gabor(p, vec4(132387.,163212.,5130.,2165.));
    k += gabor(p, vec4(154873.,80355.,8197.,3071.));
    k += gabor(p, vec4(151350.,199037.,43041.,5469.));
    k += gabor(p, vec4(186593.,107970.,111627.,7344.));
    k += gabor(p, vec4(18063.,119220.,179929.,147663.));
    k += gabor(p, vec4(159436.,116040.,26135.,6655.));
    k += gabor(p, vec4(185097.,214574.,28208.,28520.));
    k += gabor(p, vec4(145711.,176775.,40967.,3583.));
    k += gabor(p, vec4(127766.,244817.,40502.,7053.));
    k += gabor(p, vec4(162639.,183060.,96382.,48787.));
    k += gabor(p, vec4(136485.,121975.,22018.,2464.));
    k += gabor(p, vec4(163123.,60795.,13826.,2559.));
    k += gabor(p, vec4(137527.,2708.,37384.,3401.));
    k += gabor(p, vec4(129199.,79091.,13886.,14016.));
    k += gabor(p, vec4(128172.,209464.,15415.,12586.));
    k += gabor(p, vec4(75117.,175731.,44053.,4575.));
    k += gabor(p, vec4(156417.,237511.,3076.,3558.));
    k += gabor(p, vec4(127303.,227583.,20034.,12453.));
    k += gabor(p, vec4(137476.,29717.,16403.,15540.));
    k += gabor(p, vec4(86185.,28808.,13314.,2559.));
    k += gabor(p, vec4(88247.,183488.,5124.,3203.));
    k += gabor(p, vec4(95426.,55679.,16416.,16422.));
    k += gabor(p, vec4(145773.,4825.,13870.,6286.));
    k += gabor(p, vec4(100059.,173631.,39434.,5296.));
    k += gabor(p, vec4(84684.,36170.,6151.,6211.));
    k += gabor(p, vec4(139580.,40774.,25670.,23968.));
    k += gabor(p, vec4(160576.,123043.,18460.,18854.));
    k += gabor(p, vec4(76647.,172610.,12306.,2844.));
    k += gabor(p, vec4(163583.,222336.,105180.,104503.));
    k += gabor(p, vec4(131364.,12861.,15889.,14429.));
    k += gabor(p, vec4(137620.,53838.,124392.,66184.));
    k += gabor(p, vec4(135935.,159062.,15374.,12487.));
    k += gabor(p, vec4(166594.,233555.,66587.,4419.));
    k += gabor(p, vec4(177885.,108173.,5651.,4095.));
    k += gabor(p, vec4(151814.,213188.,5128.,5286.));
    k += gabor(p, vec4(183589.,36196.,27653.,3583.));
    k += gabor(p, vec4(61734.,176663.,121985.,113710.));
    k += gabor(p, vec4(154877.,207934.,5125.,5535.));
    k += gabor(p, vec4(130818.,90536.,6658.,2559.));
    k += gabor(p, vec4(72477.,53974.,66709.,19575.));
    k += gabor(p, vec4(188140.,261739.,18946.,2464.));
    k += gabor(p, vec4(154372.,153126.,3074.,2226.));
    k += gabor(p, vec4(167692.,2885.,32287.,12631.));
    k += gabor(p, vec4(144112.,211456.,25115.,24818.));
    k += gabor(p, vec4(177898.,105612.,17453.,15049.));
    k += gabor(p, vec4(178015.,211026.,4635.,3698.));
    k += gabor(p, vec4(143182.,199250.,8201.,8404.));
    k += gabor(p, vec4(131732.,213409.,21512.,3967.));
    k += gabor(p, vec4(107906.,95848.,107726.,33791.));
    k += gabor(p, vec4(132170.,163044.,95820.,14269.));
    k += gabor(p, vec4(174336.,211771.,31320.,22987.));
    k += gabor(p, vec4(86315.,189800.,84506.,12061.));
    k += gabor(p, vec4(133782.,209019.,40477.,4045.));
    k += gabor(p, vec4(93480.,247120.,10244.,4307.));
    k += gabor(p, vec4(163096.,140626.,12806.,2218.));
    k += gabor(p, vec4(128759.,194262.,4613.,5052.));
    k += gabor(p, vec4(123658.,80742.,3587.,3684.));
    k += gabor(p, vec4(158025.,145321.,9222.,2310.));
    k += gabor(p, vec4(74991.,15406.,59752.,59639.));
    k += gabor(p, vec4(160595.,80264.,12341.,9087.));
    k += gabor(p, vec4(94493.,11262.,21047.,11390.));
    k += gabor(p, vec4(183077.,157649.,10766.,4245.));
    k += gabor(p, vec4(110357.,239099.,31283.,10751.));
    k += gabor(p, vec4(128758.,195555.,5125.,3583.));
    k += gabor(p, vec4(128805.,236793.,14354.,14335.));
    k += gabor(p, vec4(159376.,106977.,95840.,95933.));
    k += gabor(p, vec4(153352.,71723.,3075.,3258.));
    k += gabor(p, vec4(156931.,108356.,4102.,2559.));

    // Don't add speckles in preview!
    if (resolution.y >= 200.0) {
        k += 0.12 * (hash12(gl_FragCoord.xy)*2.0 - 1.0);
    }
    
    glFragColor.xyz = vec3(0.5*k + 0.5);                 
    
}
