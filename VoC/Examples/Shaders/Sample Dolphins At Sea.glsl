#version 420

// original https://www.shadertoy.com/view/ssGSzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define dChance .15
#define animSpeed 2.7
#define scrollSpeed 0.1
#define maxHeight .8
#define maxAngle .7
#define blur 0.02
#define numLayers 5
#define dolphinColor vec4(vec3(107, 107, 153) * 1./255., 1)
#define seaColor vec4(vec3(128, 143, 255) * 1./255., 1)
#define skyColor1 vec3(195, 209, 230) * 1./255.
#define skyColor2 vec3(222, 244, 255) * 1./255.
#define hazeColor vec3(1) * .8

float Hash11(float value) {
    value = mod(value, 500.); // Limit value to this range otherwise hash gives weird results.
    return fract(384.545 * sin(value * 34.322 + 143.));
}

mat2x2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2x2(c, -s, s, c);
}

float sdEllipse(vec2 p, vec2 ab)
{
    p = abs(p); 
    if( p.x > p.y ) { p=p.yx;ab=ab.yx; }
    float l = ab.y*ab.y - ab.x*ab.x;
    float m = ab.x*p.x/l;      
    float m2 = m*m; 
    float n = ab.y*p.y/l;
    float n2 = n*n; 
    float c = (m2+n2-1.0)/3.0;
    float c3 = c*c*c;
    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;
    float co;
    if( d<0.0 ) {
        float h = acos(q/c3)/3.0;
        float s = cos(h);
        float t = sin(h)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
    } else {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
        float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
    }
    vec2 r = ab * vec2(co, sqrt(1.0-co*co));
    return length(r-p) * sign(p.y-r.y);
}

float ellipse(vec2 p, vec2 c, vec2 ab, float thickness)
{
    return smoothstep(1.-thickness, 1., 1. - sdEllipse(p-c, ab));
}

float dolphin(vec2 p, float angle) {
    p *= Rot(angle);
    
    float d = 0.;
    
    // Body
    d = max(ellipse(p, vec2(0), vec2(.4, .25), 0.01) - ellipse(p, vec2(0, -0.2), vec2(.5, .25), 0.01), 0.);
    
    // Mouth
    mat2x2 rotMouth = Rot(0.7);
    d = max(d, ellipse(rotMouth*p, rotMouth*vec2(-.35, .025), vec2(.15, .02), 0.01));
    
    // Fin
    d = max(d, max(ellipse(p, vec2(0.05, .2), vec2(.14, .13), 0.01) - ellipse(p, vec2(0.13, 0.2), vec2(.1, .16), 0.01), 0.));
    
    // Flippers
    d = max(d, max(ellipse(p, vec2(-0.1, .01), vec2(.14, .13), 0.01) - ellipse(p, vec2(-0.06, 0.), vec2(.1, .18), 0.01), 0.));

    // Tail
    mat2x2 rotTail = Rot(0.3);
    d = max(d, max(ellipse(p, vec2(0.43, -.14), vec2(.1, .16), 0.01) - 
                    ellipse(p, vec2(0.5, -.24), vec2(.19, .18), 0.01) -
                    ellipse(rotTail*p, rotTail*vec2(0.475, -.24), vec2(.02, .2), 0.01), 0.));
                    
    return d;
}

float SeaHeight(float x, float t) {
    return sin(x * .3) * .3 + sin(x * 2.145) * .1 + sin(x * .7 + t * 4.) * .06;
}

vec4 Layer(vec2 uv, float time, float layerFactor, float haze, float scroll, float wave, float lower, float scale) {
    float randLayer = Hash11((layerFactor + 2.3) * 13.3);
    
    uv.x += randLayer * 100.; // Shift
    uv.y += lower; // Decrease height from horizon
    uv *= scale;
    
    float panOffs = time * scrollSpeed * scroll * scale;
    
    vec2 dUV = vec2(uv.x + panOffs * .8, uv.y);

    vec4 col = vec4(0.);
    float id = floor(dUV.x); // Index value of the current box.
    vec2 luv = vec2(fract(dUV.x) - 0.5, uv.y); // Origin is in the center of each box, in range of [-.5, .5] in x axis.
    
    float rand1  = Hash11((id + 14.67) * 50.3 + randLayer * 50.7);
    float rand2  = fract(rand1 * 532.54);
    float rand3  = fract(rand2 * 92.54);

    float t = time * animSpeed + rand1 * 1000.;
    
    float heightFactor = sin(t) * maxHeight * mix(1., .5, rand3);
    float angleFactor = -cos(t) * maxAngle;
    
    vec2 dolphinOffs = vec2(0, .3 + heightFactor);
    float dolphinScale = 1. + rand3;
    vec4 dolphinVal = dolphin((luv + dolphinOffs) * vec2(dolphinScale), angleFactor) * float(rand2 < dChance) * dolphinColor;
    
    vec4 seaVal = smoothstep(blur, -blur, uv.y+SeaHeight(uv.x-panOffs, time * wave)) * seaColor;
    col = mix(dolphinVal, seaVal, seaVal.a);
    col.rgb = mix(col.rgb, hazeColor, haze);
    
    return col;
}
 
void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    
    vec3 col = mix(skyColor2, skyColor1, 4.*uv.y);
    
    for (float i = 0.; i < 1.; i += 1. / float(numLayers)) {
        float scale = mix(15., .8, i);
        float scroll = mix(.3, 3., i);
        float waves = mix(.1, .8, i);
        float lower = mix(.13, .4, i);
        
        vec4 layer = Layer(uv, time, i, 1. - i, scroll, waves, lower, scale);
        col = mix(col, layer.rgb, layer.a);
    }

    glFragColor = vec4(col, 1);
}
