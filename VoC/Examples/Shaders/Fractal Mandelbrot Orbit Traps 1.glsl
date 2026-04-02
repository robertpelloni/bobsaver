#version 420

// original https://www.shadertoy.com/view/WdfGzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 complexMultiply( vec2 a, vec2 b )
{
    return vec2(dot(a, b * vec2(1.,-1.)), dot(a, b.yx));
}
vec2 complexPower( vec2 a, int power )
{
    vec2 o = vec2(1.,0.);
    int i = 0;
    while(i < power) {
        complexMultiply(o, a);
        i++;
    }
    return o;
}
vec2 mandelbrot(vec2 z, vec2 c, int power) {
    return complexMultiply(z, z) + c;
    //return complexPower(z, power) + c;
}
vec2 pinwheel(float t) {
    float BIGF = .25;
    float LITTLEF = .9;
    BIGF *= 4.;
    LITTLEF *= 4.;    
    float BIGR = 1.;
    float LITTLER = .4;
    BIGR *= 2.;
    LITTLER *= 2.;
    return (BIGR - LITTLER) * vec2(cos(BIGF * t), sin(BIGF * t)) +
        LITTLER * vec2(cos(LITTLEF * t), sin(LITTLEF * t));
}
#define ITERATIONS 500
#define modi(a, b) ((a) - ((a) / (b)) * (b))
struct linetrap {
    vec2 base;
    vec2 dir;
    vec3 cola;
    vec3 colb;
    vec3 colc;
    float weight;
    int num;
    float dist;
    float mean;
    float var;
};
struct pointtrap {
    vec2 point;
    vec3 cola;
    vec3 colb;
    vec3 colc;
    float weight;
    int num;
    float dist;
    float mean;
    float var;
};
    #define AA 0
void main(void)
{
    
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+vec2(float(m),float(n))/float(AA)))/resolution.y;
        float w = float(AA*m+n);
        float time = time + 0.5*(1.0/24.0)*w/float(AA*AA);
#else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
        float time = time;
#endif
    
        float zoo = 0.62 + 0.38*cos(.07*time);
        float coa = cos( 0.15*(1.0-zoo)*time );
        float sia = sin( 0.15*(1.0-zoo)*time );
        zoo = pow( zoo,8.0);
        vec2 xy = vec2( p.x*coa-p.y*sia, p.x*sia+p.y*coa);
        vec2 c = vec2(-.745,.186) + xy*zoo;
        
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2. * gl_FragCoord.xy/resolution.y - (resolution.xy / resolution.y);
    float scale = 1.2;
    scale = 5e-2;
    vec2 shift = vec2(.5, 0.);
    shift = vec2(1.4, .098);
    uv = uv * scale - shift;
        uv = c;
    
    vec2 z = uv, dz = vec2(0.);
        /*
        dz = vec2(1.);
        uv = vec2(-.1,.7);
        uv = vec2(-.79,.15);
        uv = vec2(-.162,1.04);
        uv = vec2(.3,-.01);
        //uv = vec2(-1.476,.0);
        //uv = vec2(-.12,-.77);
        //uv = vec2(.28,.008);
        */
    int iterations = 0;
    float bailout = 2.;
    bailout = 2e5;
    float bailoutradius = 0., bailoutiteration = 0.;
    int power = 2;
    float t = .59;
    vec2 pointtrap = pinwheel(t);
    vec2 linetrappoint = vec2(1., 0.);
    t = 9.16;
    //t = 0.;
    linetrappoint = pinwheel(t);
    vec2 linetrapdir = normalize(vec2(1., 1.));
    float pointorbit = 1e10;
    vec2 innerpointtrap = vec2(0.);
    float innerpointorbit = 1e10;
    
    #define LINETRAPS 6
    linetrap linetraps[LINETRAPS];
    //*
    for(int i = 0; i < 5; i++) {
        float a = float(i - 2) * 3.14159 / (6. * 10.);
        linetraps[i] = linetrap(
            linetrappoint,
            mat2(cos(a), sin(a), -sin(a), cos(a)) * linetrapdir,
            //vec3(.5,0.,1.),
            vec3(float(0xEE) / 255., float(0x78) / 255., float(0x6E) / 255.),
            //.1 * vec3(1.,1.,0.),
            vec3(float(0xA2) / 255., float(0xCC) / 255., float(0xB6) / 255.),
            //vec3(0.,0.,1.),
            vec3(float(0xEE) / 255., float(0x78) / 255., float(0x6E) / 255.),
            .2,
            0,
            1e10,
            0.,
            0.
        );
    }
    //*/
    t = 0.;
    //*
    linetraps[5] = linetrap(
        pinwheel(t),
        normalize(vec2(1., 2.)),
        //vec3(0.,1.,1.),
        vec3(float(0xFC) / 255., float(0xEE) / 255., float(0xB5) / 255.),
        .0 * vec3(1.,0.,1.),
        //vec3(0.,1.,0.),
        vec3(float(0xFC) / 255., float(0xEE) / 255., float(0xB5) / 255.),
        .5,
        0,
        1e10,
        0.,
        0.
    );
    //*/
    
    while(iterations < ITERATIONS && length(z) < bailout) {
        dz = 2. * complexMultiply(z, dz) + vec2(1.,0.);
        z = mandelbrot(z, uv, power);
        pointorbit = min(pointorbit, distance(pointtrap, z));
        innerpointorbit = min(innerpointorbit, distance(innerpointtrap, z));
        for(int i = 0; i < LINETRAPS; i++) {
            vec2 ld = z - linetraps[i].base;
            vec2 lp = dot(ld, linetraps[i].dir) * linetraps[i].dir;
            float d = length(ld - lp);
            linetraps[i].num = iterations;
            linetraps[i].dist = min(linetraps[i].dist, d);
            linetraps[i].mean =
                float(iterations) / float(iterations + 1) * linetraps[i].mean +
                1. / float(iterations + 1) * d;
            linetraps[i].var += d * d;
        }
        iterations++;
        if(iterations >= ITERATIONS || length(z) >= bailout) {
            bailoutradius = length(z);
            bailoutiteration = float(iterations);
        }
    }
    for(int i = 0; i < LINETRAPS; i++)
        linetraps[i].var = linetraps[i].var / float(linetraps[i].num) -
        pow(linetraps[i].mean, 2.);
    float d = 0.5*sqrt(dot(z,z)/dot(dz,dz))*log(dot(z,z));
    float escape = 1. - log(log(length(z))/log(bailout))/log(float(power));

    // Output to screen
    float minside = iterations < ITERATIONS ? 1. : 0.;
    float cinside = length(uv) < 1. ? 1. : 0.;
    
    vec3 escapetimecolor = mix(vec3(0.), mix(
        vec3(0.),
        vec3(1., 0., 0.),
        bailoutiteration / float(ITERATIONS)
    ), minside);
    vec3 distancecolor = mix(vec3(0.), mix(
        vec3(1., 0., 0.),
        vec3(0.),
        pow(d, .125)
    ), minside);
    const int grade = 4;
    const int cols = 7;
    vec3 histogramcolors[grade * cols];
    histogramcolors[0] = vec3(1.,0.,0.);
    histogramcolors[grade] = vec3(1.,.5,0.);
    histogramcolors[2 * grade] = vec3(1.,1.,0.);
    histogramcolors[3 * grade] = vec3(0.,1.,0.);
    histogramcolors[4 * grade] = vec3(0.,1.,1.);
    histogramcolors[5 * grade] = vec3(0.,0.,1.);
    histogramcolors[6 * grade] = vec3(1.,0.,1.);
    for(int i = 0; i < cols; i++)
        for(int j = 1; j < grade; j++)
            histogramcolors[i*grade+j] = mix(
                histogramcolors[i*grade],
                histogramcolors[(i == cols - 1 ? 0 : i + 1)*grade],
                float(j) / float(grade)
            );
    vec3 histogramcolor = mix(
        vec3(0.),
        histogramcolors[modi(iterations, grade * cols)],
        minside
    );
    vec3 histogramcolora = histogramcolor;
    vec3 histogramcolorb = mix(
        vec3(0.),
        histogramcolors[modi(iterations + 1, grade * cols)],
        minside
    );
    bool useescape = true;
    vec3 histogramcolori = mix(
        histogramcolora,
        histogramcolorb,
        useescape ? escape : 1.
    );
    vec3 pointorbitcolor = mix(
        vec3(0.),
        mix(
            //vec3(1.,0.,0.),
            vec3(float(0xEE) / 255., float(0x78) / 255., float(0x6E) / 255.),
            vec3(0.),
            clamp(pointorbit, 0., 1.)
        ),
        minside
    );
    vec3 lineorbitcolor = vec3(0.);
    for(int i = 0; i < LINETRAPS; i++)
        lineorbitcolor += mix(
            vec3(0.),
            mix(
                mix(
                    linetraps[i].cola,
                    linetraps[i].colc,
                    log(float(linetraps[i].num + 1)) / log(float(ITERATIONS))
                ),
                linetraps[i].colb,
                //linetraps[i].dist
                clamp(linetraps[i].dist, 0., 1.)
                //clamp(log(linetraps[i].mean)/log(bailout), 0., 1.)
            ),
            minside
        ) * linetraps[i].weight;
    vec3 innerpointorbitcolor = mix(
        mix(
            1.5 * vec3(float(0xFC) / 255., float(0xEE) / 255., float(0xB5) / 255.),
            -2. + vec3(float(0xEE) / 255., float(0x78) / 255., float(0x6E) / 255.),
            clamp(innerpointorbit, 0., 1.)
        ),
        vec3(0.),
        minside
    );
    float shade = 1.;
    glFragColor = vec4(
        vec3(minside) * vec3(1., 1. - cinside, 1. - cinside) * shade,
        1.0
    );
    glFragColor = vec4(escapetimecolor * shade,1.0);
    glFragColor = vec4(distancecolor * shade,1.0);
    glFragColor = vec4(histogramcolor * shade,1.0);
    glFragColor = vec4(histogramcolori * shade,1.0);
    //*
    glFragColor = vec4(pointorbitcolor * shade,1.0);
    glFragColor = vec4(lineorbitcolor * shade,1.0);
    glFragColor = vec4((pointorbitcolor + lineorbitcolor + innerpointorbitcolor) * shade,1.0);
    //glFragColor = vec4(vec3(linetraps[2].dist) * shade,1.0);
    //*/
}
