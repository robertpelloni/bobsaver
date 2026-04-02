#version 420

// original https://www.shadertoy.com/view/4Xd3WM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.283185
#define PI 3.141592

//vec4 layColor(vec4 back, vec4 front) {
//    return vec4(mix(back.rgb, front.rgb, front.a), min(1., front.a + back.a));
//}

mat2 rotation(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

vec4 layColor(vec4 back, vec4 front) {
    back.a *= 1. - front.a;
    float a = front.a + back.a;
    return vec4(
        (a < 0.001) ? vec3(0.) : 
            (back.rgb * back.a + front.rgb * front.a) / a,
        a
    );
}

float customLength(vec2 p, float k) {
    p = abs(p);
    return pow(pow(p.x, k) + pow(p.y, k), 1. / k);
}

float trapezoid(vec2 uv, float blur, float wb, float wt, float yb, float yt) {
    float m = smoothstep(-blur, blur, uv.y - yb);
    m *= smoothstep(blur, -blur, uv.y - yt);
    float w = mix(wb, wt, (uv.y - yb) / (yt - yb));
    m *= smoothstep(blur, -blur, abs(uv.x) - w);
    return m;
}

float circle(vec2 uv, float blur, float radius) {
    return smoothstep(blur, -blur, length(uv) - radius);
}

float rectangle(vec2 uv, float blur, vec2 size) {
    vec2 d = abs(uv) - size;
    float l = length(max(d, 0.)) + min(0., max(d.x, d.y));
    return smoothstep(blur, -blur, l);
}

vec4 tree(vec2 uv, float blur, vec3 color, float shake) {
    uv = (uv - vec2(0., 0.)) * rotation(shake * pow(uv.y, 2.));

    float m = trapezoid(uv, blur, .04, .04, -.5, .25);
    float shadow = trapezoid(uv + vec2(.22, 0.), blur, .0, .4, .10, .25);
    m += trapezoid(uv, blur, .23, .12, .25, .5);
    shadow += trapezoid(uv - vec2(.15, 0.), blur, .0, .5, .44, .5);
    m += trapezoid(uv, blur, .18, .06, .5, .75);
    shadow += trapezoid(uv + vec2(.19, 0.), blur, .0, .5, .71, .75);
    m += trapezoid(uv, blur, .11, .0, .75, 1.);
    color -= vec3(shadow * .3);
    color = max(color, vec3(0.));
    return vec4(color, m);
}

float smoke(vec2 uv, float t, float blur, float id) {
    //float wave = 0.;
    //float reps = 2. + fract(sin(id * 534.24 + 32.2353) * 423.34 + .762) * 3.;
    //for (float rep = 0.; rep < reps; rep += 1.) {
    //    float r1 = fract(sin(rep * 411.4 + 42.53) * 531.4 * (sin(id * 840.1 + 554.2) + 3.33));
    //    float r2 = fract(.432 + sin(rep * 734.4 + 323.13) * 812.5 * (sin(id * 200.1 + 54.2) + .51));
    //    float r3 = fract(.12 + sin(rep * 259.11 + 94.1) * 240.5 * (sin(id * 333.1 + 2.2) + .139));
    //    float r4 = fract(.129 + sin(rep * 324.11 + 91.4) * 992.1 * (sin(id * 111.1 + 1.5) + .424));
    //    wave += (r1 * pow(r3, .8) * .2) * sin(uv.y * (r3 * 20. + 5.) - t * (r4 * 2.));
    //}
    uv.y /= 2.;
    
    float wave
        = .1 * sin(uv.y * 15. - t * .5)
        + .1 * sin(pow(uv.y, 2.) * 5. + 2. - t * .4)
        + .1 * sin(pow(abs(uv.y), .5) * 30. + .02 - t * .5);
    float y = uv.y - 1.;
    float x = (uv.x + wave * uv.y + .5 * pow(uv.y, 1.4))
        / (.1 + .2 * pow(uv.y, 3.));
        
    if (uv.y < 0.) {
        y = 2. - uv.y;
    }
    float d = pow(x, 2.) + pow(y, 2.) - 1.;
    
    float a = smoothstep(blur, -blur, d);
    a *= 1. - uv.y / 2.;
    return a;
}

vec4 house(vec2 uv, float blur, vec3 col, float t, bool hasSmoke, float smokeHeight, float smokeVis, bool lightOn) {
    vec4 outCol = vec4(0.);
    // base top
    outCol = layColor(outCol, vec4(
        col - vec3(.0),
        trapezoid(uv, blur, .65, .0, 0.99, 1.4)
    ));
    // base
    outCol = layColor(outCol, vec4(col - vec3(.0), trapezoid(uv, blur, .6, .65, 0., 1.)));
    // door
    float door = trapezoid(uv, blur, .23, .25, 0., 0.6);
    door += trapezoid(uv, blur, .25, .0, 0.6, 0.8);
    outCol = layColor(outCol, vec4(lightOn ? vec3(1., 1., 0.) : col - .2, door));
    // roof shadow
    float roofShadow = trapezoid(vec2(abs(uv.x) - .2, uv.y - 1.2) * rotation(PI / 5.), blur, .7, .7, -.1, .1);
    outCol.rgb -= vec3(.3) * roofShadow;
    // smoke
    if (hasSmoke) {
        outCol = layColor(outCol, vec4(
            col,
            smoke((uv - vec2(.5, 1.6)) / vec2(1., smokeHeight), t * 20., blur + 1., 0.) * smokeVis
        ));
    }
    // smoker
    outCol = layColor(outCol, vec4(
        col - vec3(.2),
        trapezoid(uv - vec2(.5, 0.), blur, .1, .13, 1.2, 1.6)
    ));
    // roof
    float roof = trapezoid(
        vec2(abs(uv.x) - 0.3, uv.y - 1.3) * rotation(PI / 5.),
        blur, .7, .7, -.1, .1
    );
    // stairs
    outCol = layColor(outCol, vec4(col, trapezoid(uv, blur, .8, .8, -.2, 0.01)));
    outCol = layColor(outCol, vec4(col, trapezoid(uv, blur, 1., 1., -.4, -.201)));
    outCol = layColor(outCol, vec4(col, trapezoid(uv, blur, 1.2, 1.2, -.6, -.401)));
    
    outCol = layColor(outCol, vec4(col, roof));
    return outCol;
}

vec4 balloon(vec2 uv, float blur, vec3 col) {
    uv *= 2.;
    vec4 outCol = vec4(0.);
    if (uv.y > -.8) {
        uv.x /= pow((uv.y + 1.) / 2., .4);
        outCol = layColor(outCol, vec4(col, circle(uv, blur, 1.)));
        outCol = layColor(outCol, vec4(col - .1, circle(uv * vec2(1.3, 1.), blur, 1.)));
        outCol = layColor(outCol, vec4(col, circle(uv * vec2(2.2, 1.), blur, 1.)));
        //outCol = layColor(outCol, vec4(col - .2, circle(uv * vec2(3., 1.), blur, 1.)));
    } else {
        uv.y += .8;
        const vec2 boxSize = vec2(.27, .02);
        const vec2 boxPos = vec2(0., -.25);
        // CIRCLED BOTTOM
        //float l = length(uv - vec2(boxPos.x, boxPos.y - boxSize.y)) - boxSize.x;
        //l = max(l, uv.y - boxPos.y);
        //outCol = layColor(outCol, vec4(col,
        //    rectangle(uv - boxPos, blur, boxSize)
        //    + smoothstep(blur, -blur, l)
        //));
        outCol = layColor(outCol, vec4(col - .1,
            rectangle(vec2(abs(uv.x) - .17, uv.y + .15), blur, vec2(0.05, .15))
        ));
        outCol = layColor(outCol, vec4(col,
            trapezoid(uv - boxPos, blur, .25, .3, -.3, .02)
        ));
        //outCol = layColor(outCol, vec4(col - .2,
        //    trapezoid((uv - boxPos) * vec2(2.5, 1.), blur, .25, .3, -.3, .02)
        //));
        
    }
    
    return outCol;
}

float hillHeight(float x) {
    return sin(x * .8) * .5 + sin(x * 2. + .3) * .3 + sin(x * 5. + 20.) * .1;
}

float shakeTree(float t) {
    return sin(t) * .3 + sin(t * 1.4 + 1.) * .2 + sin(t * 3. + 2.43) * sin(t * 1.5 + 3.42);
}

vec4 hill(vec2 uv, float blur, vec3 color, float slotWidth) {
    uv.y *= slotWidth;
    float h = hillHeight(uv.x - .5) - .1;
    float a = smoothstep(blur, -blur, uv.y - h);
    float s = 0.;
    
    for (float i = 0.; i < 2.; i++) {
        vec2 p = uv;
        float id = floor(p.x / 6.);
        p.x = mod(p.x + i * 3., 6.) - .2;
        p.y -= h;

        p *= 3.;
        float shift = pow(-p.y, 2.) * .02 + 1.5;
        float thickness = pow((-p.y), 1.) / 20. + 0.2;
        thickness *= 1. + .5 * fract(sin(id * 432.13 + .322) * 534.12 + .43);
        float waveShift = 10. * fract(sin(id * 432.13 + .322) * 534.12 + .43);
        float waveFreq = 4. * fract(sin(id * 910.11 + .24) * 910.1 + .19);
        float wave = sin(p.y * waveFreq + waveShift) * .5;
        float d = abs(wave + shift - p.x) / thickness - 1.;
        //float vis = .2 * (fract(sin(id * 531.81 + .42) * 429.12 + .1) - .7);
        float vis = -.1;
        s += vis * smoothstep(blur, -blur, d);
    }
    
    return vec4(color + vec3(s), a);
}

vec4 hillWithThings(vec2 uv, float time, float id, float blur, vec3 color, bool hasHouses) {
    float slotWidth = 2.;
    float treeId = floor(uv.x);
    float treeLayerId = fract(sin(treeId + id * 434.32 + 42.1) + sin(treeId * 942.1 + id * 32.4));
    bool isHouse = hasHouses && (fract(sin(treeLayerId * 534.15 + 4.43) + 431.4) > 0.84);
    //float shiftedId = floor(uv.x + xShift * .5);
    vec4 hill = hill(uv, blur, color, slotWidth);
    uv.x = fract(uv.x) - .5;
    
    uv *= slotWidth;
    uv.x += .3 * (fract(sin(treeId * 543.12) * 342.65) - .5) * (slotWidth - (isHouse ? slotWidth : 0.5));
    uv.y -= hillHeight(treeId);
    vec4 trees;
    if (isHouse) {
        bool dir = fract(sin(treeLayerId * 319.11 + 5.45) + 649.6) > 0.7;
        trees = house(
            uv * 2. * vec2(dir ? 1. : -1., 1.) - vec2(0., -0.3),
            blur, color, time,
            (fract(sin(treeLayerId * 756.15 + 5.41) + 539.5) > 0.4),
            0.8 + fract(sin(treeLayerId * 129.15 + 245.47) + 953.11) * .3,
            fract(sin(treeLayerId * 942.15 + .32) * 42.1 + 111.99),
            fract(sin(treeLayerId * 942.15 + .91) * 99.1) > .5
        );
    } else {
        float shake = .1 * sin(time * .3 + fract(sin(id * 200.11 + .5391) * 342.1 + .991) * 10.);
        shake += 0.05 * fract(sin(treeLayerId * 593.11 + .3411) * 904.2 + .1392);
        float shakingSpeed = 1. * sin(time * .001 + 10. * fract(sin(id * 590.5 + .532) * 324.9 + .342));
        float shakingRange = 0.2 * (fract(sin(treeLayerId * 319.1 + .4902) * 235.14 + .423) - .5);
        shake += shakingRange * shakeTree(time * shakingSpeed);
        float height = 1.2 + .5 * (fract(sin(treeLayerId * 942.11 + .3411) * 904.2 + .1392) - .5);
        trees = tree(uv / vec2(1., height), blur, color, shake);
    }
    return layColor(trees, hill);
}

vec4 balloons(vec2 uv, float time, float layerId, float blur, vec3 color) {
    float slotWidth = 2.;
    float id = floor(uv.x / slotWidth);
    float globalId = fract(77.55 * sin(layerId * 421.41 + id * 215.1) + id * 99.99);
    bool exists = .82 < fract(sin(globalId * 941.4 + .32) * 993.12);
    if (exists) {
        uv.x = mod(uv.x, slotWidth) - slotWidth / 2.;
        uv.y -= mod(globalId * 100.5 + time * .5, 10.) - 1.5;
        uv.x -= .3 * sin(globalId * 32.3 + time * 1.);
        return balloon(uv * 2., blur, color);
    } else {
        return vec4(0.);
    }
}

vec4 layer(vec2 uv, float time, float id, float blur, vec3 color, bool isFirst) {
    vec4 outCol = vec4(0.);
    if (!isFirst) {
        vec4 b = balloons(uv, time, id, blur, color);
        outCol = layColor(outCol, b);
    }
    outCol = layColor(outCol, hillWithThings(uv, time, id, blur, color, !isFirst));
    
    return outCol;
}

vec4 layers(vec2 uv, float time, vec2 shift) {
    vec4 color = vec4(0.);
    for (float i = 0.; i < 1.; i += 1. / 10.) {
        float p = pow(i, 1.7);
        float blur = mix(0.01, 0.0, p);
        vec3 layerColor = vec3(mix(.9, 0., p));
        vec2 layerUv = uv / mix(.1, 1., p);
        layerUv.x += fract(sin(i * 521.4) * 421.6) * 2000.;
        layerUv += shift;
        layerUv.y += mix(0., .4, p);
        vec4 c = layer(layerUv, time, i, blur, layerColor, false);
        //c.rgb *= mix(.9, 0., p);
        color = layColor(color, c);
        
    }
    vec4 c = layer(uv * .8 + shift + vec2(0., 0.3), time, 534.4, 0.1, vec3(0.), true);
    color = layColor(color, c);
    return color;
}

vec4 stars(vec2 inputUv, float time) {
    float a = 0.;
    for (float i = 0.; i < 1.; i += 1.) {
        vec2 uv = inputUv * rotation(time * .05);
        vec2 cellSize = vec2(.16);
        vec2 id = floor(uv / cellSize);
        float mixedId = id.x * 100. + id.y + i * 3.4291;
        bool exists = .0 < fract(sin(mixedId * 921.4 + .91) * 991.1);
        if (!exists) {
            return vec4(0.);
        }

        uv = mod(uv, cellSize) - cellSize / 2.;
        vec2 shift = vec2(
            fract(sin(mixedId * 194.4 + 5.32) * 199.12),
            fract(sin(mixedId * 932.4 + 2.99) * 483.2)
        );
        shift = (cellSize - .1) * (shift - .5);
        uv += shift;

        float size = .014 * fract(sin(mixedId * 1831.9 + .43) * 134.2);
        float brightness = pow(fract(sin(mixedId * 892.1 + .55) * 24.5 + .2), 1.4);
        float twinkleSpeed = fract(sin(mixedId * 491.1 + .54) * 876.2);
        float rot = TAU * fract(sin(mixedId * 421.2 + .84) * 321.1);
        float rotVel = fract(sin(mixedId * 791.5 + .11) * 53.2) * 2. - 1.;

        uv *= rotation(rot + time * rotVel * 2.);

        float blur = size * 1.;
        float twinkle = .7 + .3 * (sin(time * 20. * twinkleSpeed) * .5 + .5);
        float m = 1. * circle(uv, size * 4.5, size);
        m += smoothstep(blur, -blur, customLength(uv, .4) - size * 2.);
        m *= twinkle * brightness;
        m *= smoothstep(.2, .4, length(inputUv));
        a += m;
        
    }
    return vec4(vec3(1.), a);
}

vec4 sky(vec2 uv, float time) {
    vec4 color = vec4(vec3(.0), 1.);
    
    color = layColor(
        color,
        stars(uv, time)
    );
    color = layColor(
        color,
        vec4(vec3(1.), circle(uv - vec2(0, .0), 0.3, .8) * .3)
    );
    
    color = layColor(
        color,
        vec4(vec3(1.), circle(uv - vec2(0, .0), 0.1, .45) * .3)
    );
    
    color = layColor(
        color,
        vec4(vec3(1.), circle(uv - vec2(0, .0), 0.08, .3) * .6)
    );
    
    float r = .22;
    vec2 p = uv - vec2(0., 0.);
    float a = (p.y + r) / r * .7 + sin(pow(r - p.y, 4.) * 1000. + time * 8.) * .5 + .5;
    a = 1.;
    color = layColor(
        color,
        vec4(vec3(1.), a * circle(p, 0.01, r))
    );
    return color;
}

vec4 scene(vec2 uv, vec2 mouse, float time) {
    vec4 color = vec4(vec3(.0), 1.);
    
    vec4 sky = sky(uv, time);
    color = layColor(color, sky);
    //color = vec4(1.);

    vec2 shift = vec2(time * .5, .3); // ugh
    shift -= mouse * vec2(1., .2);
    vec4 l = layers(uv, time, shift);
    //l.a = max(0., l.a - .4);
    color = layColor(color, l);
    color.rgb = pow(color.rgb, vec3(4., 2.5, 0.8));
    //color.rgb = pow(color.rgb, vec3(2., 1., 3.)) * vec3(1.2, 1.2, 1.);
    
    return color;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    mouse.x -= .5;
    
    vec3 color = scene(uv, mouse, time).rgb;
    // Output to screen
    glFragColor = vec4(color, 1.0);
}

