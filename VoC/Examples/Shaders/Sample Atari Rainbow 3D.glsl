#version 420

// original https://www.shadertoy.com/view/XlVBRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Atari logo - Raymarched by Del 25/11/2018

float atari(vec2 p)
{
    p*=0.15;
    vec2 b = vec2(0.08,0.5);
    vec2 v1 = abs(p)-b;
    float d1 = length(max(v1,vec2(0))) + min(max(v1.x,v1.y),0.0);

    p.x = -abs(p.x);
    p+=vec2(0.25,0.0);

    float c = smoothstep(0.0, 1.0, pow(clamp(-p.y, 0.0, 1.0), 1.2));
    p.x +=  c;
    b.x += c*0.1;
    v1 = abs(p)-b;
    float d2 = length(max(v1,vec2(0))) + min(max(v1.x,v1.y),0.0);
    return min(d1,d2)*8.0;
}

mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}
#define    TAU 6.28318

float map(vec3 p)
{
    float time2 = time-0.25;
    float twist = 0.5+sin(fract(time2*0.55)*TAU)*0.5;
    twist *= p.y * 0.125;
    p.xz *= rotate(twist+fract(time2*0.2)*TAU);
    
    float dist = atari(p.xy);
    
    float dep = 0.5;
    vec2 e = vec2( dist, abs(p.z) - dep );
    dist = min(max(e.x,e.y),0.0) + length(max(e,0.0));
    dist -= 0.225;        // rounding
    return dist;
}

// Tetrahedral normal, to save a couple of "map" calls. Courtesy of IQ.
vec3 normal( in vec3 p )
{
    // Note the slightly increased sampling distance, to alleviate
    // artifacts due to hit point inaccuracies.
    vec2 e = vec2(0.0025, -0.0025); 
    return normalize(
        e.xyy * map(p + e.xyy) + 
        e.yyx * map(p + e.yyx) + 
        e.yxy * map(p + e.yxy) + 
        e.xxx * map(p + e.xxx));
}

// Smooth HSV to RGB conversion 
vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    

    return c.z * mix( vec3(1.0), rgb, c.y);
}
vec3 render(vec2 uv)
{
    float time1 = time-1.15;
    vec3 ro = vec3(0.0, 0.0, -13.0);
    vec3 rd = normalize(vec3(uv, 1.95));
    vec3 p = vec3(0.0);
    float t = 0.;
    for (int i = 0; i < 240; i++)
    {
        p = ro + rd * t;
        float d = map(p);
        if (d < .001 || t > 30.) break;
        t += d *0.5;
    }
    
    vec3 c = vec3(0.35,0.35,0.45);
    c*= 1.2-abs(uv.y);
    
    if (t<30.0)
    {
             vec3 lightDir = normalize(vec3(10.0, 13.5, -13.0));

        vec3 nor = normal(p);

        float dif = max(dot(nor, lightDir), 0.0);
        
        float h = time*0.25-p.y*0.09;
        vec3 c1 = hsv2rgb_smooth(vec3(h,1.0,1.3));
        
        float tf = 0.1;
        c1 += reflect(vec3(p.x*tf, p.y*tf, 0.0), nor);
        c1 *= dif;
        
        
        vec3 ref = reflect(rd, nor);
        float spe = max(dot(ref, lightDir), 0.0);
        vec3 spec = vec3(2.0) * pow(spe, 16.);
        c1 = c1 + spec;
        vec3 c2 = c + spec;            // ghostly background + just spec

         float bl = sin(fract(time1/12.0) * TAU);
        bl = smoothstep(0.0, 1.0, bl);
        c = mix(c1,c2,bl);
        
    }

    c *= 1.0 - 0.3*length(uv);
    return c;
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col = render(uv);
    glFragColor = vec4(col, 1.);
}

