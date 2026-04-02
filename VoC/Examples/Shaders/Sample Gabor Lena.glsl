#version 420

// original https://www.shadertoy.com/view/XltGzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Lena, by mattz

   Famous image compression benchmark, composed with 128 Gabor functions.
   https://en.wikipedia.org/wiki/Lenna

   See https://www.shadertoy.com/view/4ljSRR for technical details

*/

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
            
    float cr = cos(q0.y);
    float sr = sin(q0.y);
        
    vec2 st = vec2(q0.w, q1.z);

    // Rotate and translate point
    p = mat2(cr, -sr, sr, cr) * (p - vec2(q0.x, q1.x));    
            
    // Handle appearing at the start of filter
    q1.w *= smoothstep(cnt, cnt+0.5, time*32.0);
    ++cnt;

    // amplitude * gaussian * sinusoid
    return q1.w * exp(dot(vec2(-0.5), p*p/(st*st))) * cos(p.x*6.2831853/q0.z+q1.y);
    
}

void main(void) {
        
    vec2 p = (gl_FragCoord.xy - 0.5*resolution.xy) * 1.2 / resolution.y;
    p.y = -p.y;
    p += 1.0;
    
    float k = 0.0;

        k += gabor(p, vec4(217654.,7795.,103043.,31071.));
    k += gabor(p, vec4(98044.,120991.,74307.,24761.));
    k += gabor(p, vec4(178352.,65731.,28193.,16514.));
    k += gabor(p, vec4(96980.,159816.,17969.,8540.));
    k += gabor(p, vec4(91513.,188769.,241193.,15072.));
    k += gabor(p, vec4(110080.,29304.,49736.,35016.));
    k += gabor(p, vec4(239462.,122482.,158231.,23969.));
    k += gabor(p, vec4(224845.,125982.,13892.,9002.));
    k += gabor(p, vec4(183061.,142953.,26649.,23700.));
    k += gabor(p, vec4(140977.,50440.,16939.,8253.));
    k += gabor(p, vec4(247295.,90198.,19048.,15958.));
    k += gabor(p, vec4(41719.,109726.,25615.,8439.));
    k += gabor(p, vec4(337.,177819.,160813.,10422.));
    k += gabor(p, vec4(3071.,126778.,34375.,34449.));
    k += gabor(p, vec4(181455.,260571.,17933.,13442.));
    k += gabor(p, vec4(99058.,27254.,8718.,2047.));
    k += gabor(p, vec4(229068.,254591.,9242.,9310.));
    k += gabor(p, vec4(184699.,131357.,7183.,3665.));
    k += gabor(p, vec4(175437.,192343.,9738.,3267.));
    k += gabor(p, vec4(29303.,111735.,36491.,17975.));
    k += gabor(p, vec4(95467.,18066.,21012.,12417.));
    k += gabor(p, vec4(31460.,215837.,13340.,3681.));
    k += gabor(p, vec4(209032.,254463.,39438.,2649.));
    k += gabor(p, vec4(261832.,187456.,68651.,33323.));
    k += gabor(p, vec4(180931.,29721.,29825.,29713.));
    k += gabor(p, vec4(196429.,150923.,4116.,2657.));
    k += gabor(p, vec4(217487.,2444.,66071.,5119.));
    k += gabor(p, vec4(159879.,23564.,6683.,6686.));
    k += gabor(p, vec4(57155.,13878.,15898.,11389.));
    k += gabor(p, vec4(47463.,136318.,10759.,2025.));
    k += gabor(p, vec4(133645.,144159.,37402.,27135.));
    k += gabor(p, vec4(132812.,228996.,81417.,6655.));
    k += gabor(p, vec4(159878.,31909.,39429.,2821.));
    k += gabor(p, vec4(83074.,123775.,187921.,13311.));
    k += gabor(p, vec4(236905.,304.,5138.,3292.));
    k += gabor(p, vec4(153894.,178410.,19499.,13844.));
    k += gabor(p, vec4(141064.,234941.,26144.,16404.));
    k += gabor(p, vec4(142502.,140823.,8722.,5176.));
    k += gabor(p, vec4(129914.,90673.,13836.,9806.));
    k += gabor(p, vec4(179497.,55663.,43014.,3583.));
    k += gabor(p, vec4(252620.,12503.,20032.,17994.));
    k += gabor(p, vec4(187285.,78816.,7686.,2047.));
    k += gabor(p, vec4(213631.,115553.,21009.,16988.));
    k += gabor(p, vec4(171852.,191248.,7690.,5755.));
    k += gabor(p, vec4(252681.,141481.,5656.,3215.));
    k += gabor(p, vec4(213247.,138111.,44554.,3057.));
    k += gabor(p, vec4(205004.,179653.,7172.,3836.));
    k += gabor(p, vec4(211634.,255864.,45061.,6143.));
    k += gabor(p, vec4(233664.,259584.,4634.,3241.));
    k += gabor(p, vec4(187742.,138582.,23108.,8753.));
    k += gabor(p, vec4(30834.,126975.,8713.,5342.));
    k += gabor(p, vec4(152306.,136306.,261813.,23573.));
    k += gabor(p, vec4(73488.,160986.,11797.,9517.));
    k += gabor(p, vec4(57452.,163391.,12317.,12362.));
    k += gabor(p, vec4(160986.,199418.,19492.,13342.));
    k += gabor(p, vec4(138124.,197785.,18953.,1913.));
    k += gabor(p, vec4(192187.,35470.,16901.,3583.));
    k += gabor(p, vec4(168616.,229259.,39940.,3071.));
    k += gabor(p, vec4(39713.,108245.,12816.,12404.));
    k += gabor(p, vec4(213912.,55289.,19582.,16407.));
    k += gabor(p, vec4(204481.,80491.,17923.,3583.));
    k += gabor(p, vec4(39233.,87039.,10259.,9780.));
    k += gabor(p, vec4(169800.,73841.,22040.,9266.));
    k += gabor(p, vec4(17270.,108670.,17413.,4954.));
    k += gabor(p, vec4(241569.,5120.,9228.,4742.));
    k += gabor(p, vec4(151739.,117759.,9223.,6898.));
    k += gabor(p, vec4(156849.,83562.,7685.,4356.));
    k += gabor(p, vec4(184002.,159272.,27763.,27660.));
    k += gabor(p, vec4(207019.,186367.,3592.,2194.));
    k += gabor(p, vec4(10965.,254269.,13850.,9824.));
    k += gabor(p, vec4(34014.,30112.,29289.,24090.));
    k += gabor(p, vec4(171296.,193306.,4610.,2320.));
    k += gabor(p, vec4(112923.,256512.,8734.,7187.));
    k += gabor(p, vec4(9415.,146432.,14856.,8964.));
    k += gabor(p, vec4(150701.,56498.,8203.,5777.));
    k += gabor(p, vec4(186189.,135182.,5665.,4140.));
    k += gabor(p, vec4(12142.,133725.,15886.,2559.));
    k += gabor(p, vec4(118978.,32767.,2061.,1677.));
    k += gabor(p, vec4(64263.,53212.,12305.,6734.));
    k += gabor(p, vec4(147145.,183386.,15363.,2559.));
    k += gabor(p, vec4(138380.,251492.,11798.,11833.));
    k += gabor(p, vec4(198980.,16994.,12825.,5731.));
    k += gabor(p, vec4(154848.,174009.,21542.,20513.));
    k += gabor(p, vec4(139373.,96255.,17543.,17421.));
    k += gabor(p, vec4(101670.,129535.,4621.,2197.));
    k += gabor(p, vec4(137612.,187509.,96265.,6655.));
    k += gabor(p, vec4(68421.,27135.,5141.,2852.));
    k += gabor(p, vec4(260861.,21925.,66065.,17540.));
    k += gabor(p, vec4(32988.,116621.,29701.,6143.));
    k += gabor(p, vec4(205508.,142336.,7174.,5222.));
    k += gabor(p, vec4(155807.,206683.,13320.,1897.));
    k += gabor(p, vec4(84283.,159604.,12834.,12325.));
    k += gabor(p, vec4(222379.,145023.,41482.,9841.));
    k += gabor(p, vec4(76919.,75902.,137271.,8863.));
    k += gabor(p, vec4(149327.,72433.,4612.,1694.));
    k += gabor(p, vec4(119942.,158720.,3089.,2249.));
    k += gabor(p, vec4(40322.,82301.,75283.,5052.));
    k += gabor(p, vec4(63720.,114610.,11282.,6788.));
    k += gabor(p, vec4(27828.,36352.,6671.,6788.));
    k += gabor(p, vec4(191178.,92323.,4610.,2273.));
    k += gabor(p, vec4(203935.,46079.,7691.,4174.));
    k += gabor(p, vec4(169302.,67110.,10248.,8299.));
    k += gabor(p, vec4(187587.,152576.,4101.,1654.));
    k += gabor(p, vec4(185077.,129041.,8718.,8293.));
    k += gabor(p, vec4(184118.,125779.,15926.,12310.));
    k += gabor(p, vec4(186776.,209547.,13321.,2559.));
    k += gabor(p, vec4(160090.,117349.,14866.,14872.));
    k += gabor(p, vec4(53141.,96767.,4613.,2845.));
    k += gabor(p, vec4(145205.,21844.,18977.,18966.));
    k += gabor(p, vec4(262036.,195355.,23144.,23064.));
    k += gabor(p, vec4(187744.,160767.,8714.,5696.));
    k += gabor(p, vec4(130530.,23022.,31773.,27738.));
    k += gabor(p, vec4(41772.,245253.,8708.,4462.));
    k += gabor(p, vec4(198942.,130144.,40025.,17937.));
    k += gabor(p, vec4(236813.,127549.,7699.,6859.));
    k += gabor(p, vec4(143986.,120319.,7712.,4134.));
    k += gabor(p, vec4(27593.,247878.,8732.,5433.));
    k += gabor(p, vec4(186497.,131521.,16395.,11295.));
    k += gabor(p, vec4(224880.,118422.,2574.,1659.));
    k += gabor(p, vec4(218668.,511.,9232.,9727.));
    k += gabor(p, vec4(237947.,130913.,3597.,1854.));
    k += gabor(p, vec4(139734.,147045.,15375.,15871.));
    k += gabor(p, vec4(123539.,161142.,9746.,7813.));
    k += gabor(p, vec4(23207.,5631.,10247.,7341.));
    k += gabor(p, vec4(241795.,126975.,10273.,4165.));
    k += gabor(p, vec4(124596.,165376.,6164.,2709.));
    k += gabor(p, vec4(169753.,114638.,47620.,3125.));
    k += gabor(p, vec4(261864.,108325.,126655.,126464.));
 

    // Don't add speckles in preview!
    if (resolution.y >= 200.0) {
        // borrowed Dave Hoskins' hash from https://www.shadertoy.com/view/4djSRW
        p = fract(p * vec2(443.8975,397.2973));
        p += dot(p.xy, p.yx+19.19);
        k += 0.12 * (fract(p.x * p.y)*2.0 - 1.0);
    }
    
    glFragColor.xyz = vec3(smoothstep(-1.0, 1.0, k));
    
}
