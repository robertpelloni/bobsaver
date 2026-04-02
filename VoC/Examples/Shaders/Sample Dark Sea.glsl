#version 420

// original https://www.shadertoy.com/view/WllBR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){
   return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float valueNoiseSimple(vec2 vl) {
   const vec2 helper = vec2(0., 1.);
    vec2 interp = smoothstep(vec2(0.), vec2(1.), fract(vl));
    vec2 grid = floor(vl);

    float rez = mix(mix(rand(grid + helper.xx),
                        rand(grid + helper.yx),
                        interp.x),
                    mix(rand(grid + helper.xy),
                        rand(grid + helper.yy),
                        interp.x),
                    interp.y);
    return rez;

}

const mat2 unique_transform = mat2( 0.85, -0.65, 0.65, 0.85 );

float fractalNoise(vec2 vl) {
    
    const float persistance = 3.0;
    float frequency = 2.3;
    const float freq_mul = 2.3;
    float amplitude = .7;
    
    float rez = 0.0;
    vec2 p = vl;
   
    float mainOfset = (time + 40.)/ 2.;
    
    vec2 waveDir = vec2(p.x+ mainOfset, p.y + mainOfset);
    float firstFront = amplitude + 
                    (valueNoiseSimple(p) * 2. - 1.);
    
    float mainwave =(.7 + (valueNoiseSimple(p) * 2. - 1.)) * valueNoiseSimple(p + (time + 40.)/ 2.);
    
    rez += mainwave;
    amplitude /= persistance;
    p *= unique_transform;
    p *= frequency;
    

    float timeOffset = time / 4.;

    
    for (int i = 1; i < 8; i++) {
        waveDir = p;
        waveDir.x += timeOffset;
        rez += amplitude * sin(valueNoiseSimple(waveDir * frequency) * .5 );
        amplitude /= persistance;
        p *= unique_transform;
        frequency *= freq_mul;
        timeOffset *= 1.025;
        timeOffset *= -1.;
    }

    return rez;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 centered_uv = uv * 2. - 1.;
    centered_uv.x *= resolution.x / resolution.y;
    
    float timeOffset = time / 5.;
    
    vec3 O = vec3(0., 0.1, 1. - timeOffset);
    float h = (O.y + 0.2 + sin(fractalNoise(vec2(O.x - 5., O.z )) / 6.5)) * 0.65;
    O.y -= h;
    
    vec3 D = normalize(vec3(centered_uv, -2.0)); //fov

    float hill;

    float L = 0.;
    int steps = 0;
    float d = 0.;
    for (int i = 0; i < 64; ++i) {
        d = (O + D*L).y + 0.2 + sin(fractalNoise(vec2((O + D*L).x - 5., (O + D*L).z )) / 6.5);
        
        L += d;
        
        if (d < .0001*L)
            break;
    }
    
    hill = d;
    
    float path = L;
    vec3 coord = O + path * D;

    vec3 resColor;
   
    vec3 lightPos = vec3(20., 90. -h, -95. - timeOffset);
    
    
    vec2 e = vec2(.0001, 0.);
   float w = coord.y + 0.2 + sin(fractalNoise(vec2(coord.x - 5., coord.z )) / 6.5); 
   
   vec3 normal =normalize(vec3(
        (coord+e.xyy).y + 0.2 + sin(fractalNoise(vec2((coord+e.xyy).x - 5., (coord+e.xyy).z )) / 6.5)- w,
       e.x,
       ((coord+e.yyx).y + 0.2 + sin(fractalNoise(vec2((coord+e.yyx).x - 5., (coord+e.yyx).z )) / 6.5)) - w));
    
 
     
     vec3 dir = lightPos - coord;
    vec3 eyeDir = O - coord;
    float dist = length(eyeDir);
    float atten = pow(0.93, dist * 7. );
    
    
    vec3 rotZccw = vec3(-normal.y, normal.xz);
    vec3 rotZcw = vec3(normal.y, -normal.x, normal.z);
    
    vec3 rotXccw = vec3(normal.x, normal.z, -normal.y);
    vec3 rotXcw = vec3(normal.x, -normal.z, normal.y);
    
    vec3 rotYccw = vec3(normal.z, normal.y, -normal.x);
    vec3 rotYcw = vec3(-normal.z, normal.y, normal.x);
    
    float rez = 0.;
    float dst = .28;

       rez+= max(0., (coord + dst * normal).y + 0.2 + sin(fractalNoise(vec2((coord + dst * normal).x - 5., (coord + dst * normal).z )) / 6.5));
    
    rez+= max(0., (coord + dst * rotXccw).y + 0.2 + sin(fractalNoise(vec2((coord + dst * rotXccw).x - 5., (coord + dst * rotXccw).z )) / 6.5));
             
    rez+=  max(0., (coord + dst * rotXcw).y + 0.2 + sin(fractalNoise(vec2((coord + dst * rotXcw).x - 5., (coord + dst * rotXcw).z )) / 6.5));
            
    rez+= max(0., (coord + dst * rotYccw).y + 0.2 + sin(fractalNoise(vec2((coord + dst * rotYccw).x - 5., (coord + dst * rotYccw).z )) / 6.5));
                    
    rez+=  max(0., (coord + dst * rotYcw).y + 0.2 + sin(fractalNoise(vec2((coord + dst * rotYcw).x - 5., (coord + dst * rotYcw).z )) / 6.5));
               
    rez+= max(0., (coord + dst * rotZccw).y + 0.2 + sin(fractalNoise(vec2((coord + dst * rotZccw).x - 5., (coord + dst * rotZccw).z )) / 6.5));
                                    
    rez+=  max(0., (coord + dst * rotZcw).y + 0.2 + sin(fractalNoise(vec2((coord + dst * rotZcw).x - 5., (coord + dst * rotZcw).z )) / 6.5));
               
       

    
    
        
    resColor = vec3(((pow(min(rez, 1.), 4.5) - 0.13725) * 1.7) * atten);

    glFragColor = vec4(resColor, 1.);
}
