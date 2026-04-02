#version 420

// original https://www.shadertoy.com/view/XXcXR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ?? Coffee Planet
// License CC0-1.0
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Deeply inspired by @kchnkrml's shader https://www.shadertoy.com/view/tltXWM. 
// Uses his 3-color noise-colorization + mix technique with some modifications 
// to fbm and offset generation that reduce total-noise calls and provide varied
// output.
// 
// Also shoutout to @kotfind for his 4D smooth noise algorithm used to create
// The base equirectangular noise. https://www.shadertoy.com/view/WsBBDK
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Planet Colors
vec3 colorA = vec3(0.2, 0.0, 0.1);
vec3 colorB = vec3(0.7, 0.3, 0.4);
vec3 colorC = vec3(1.0, 0.2, 0.4);

// Overwrites above colors and ties them to sin/cos time.
bool discomode=false;

// 4D Smoothnoise by @Kotfind (License Unkown) https://www.shadertoy.com/view/WsBBDK
float rand(in vec4 p) {
    return fract(sin(p.x*1234. + p.y*2345. + p.z*3456. + p.w*4567.) * 5678.);
}
float smoothnoise(in vec4 p) {
    const vec2 e = vec2(0.0, 1.0);
    vec4 i = floor(p);    // integer
    vec4 f = fract(p);    // fract
    
    f = f*f*(3. - 2.*f);
    
    return mix(mix(mix(mix(rand(i + e.xxxx),
                           rand(i + e.yxxx), f.x),
                       mix(rand(i + e.xyxx),
                           rand(i + e.yyxx), f.x), f.y),
                   mix(mix(rand(i + e.xxyx),
                           rand(i + e.yxyx), f.x),
                       mix(rand(i + e.xyyx),
                           rand(i + e.yyyx), f.x), f.y), f.z),
               mix(mix(mix(rand(i + e.xxxy),
                           rand(i + e.yxxy), f.x),
                       mix(rand(i + e.xyxy),
                           rand(i + e.yyxy), f.x), f.y),
                   mix(mix(rand(i + e.xxyy),
                           rand(i + e.yxyy), f.x),
                       mix(rand(i + e.xyyy),
                           rand(i + e.yyyy), f.x), f.y), f.z), f.w);
}
float fbm(vec3 x) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(1);
    for (int i = 0; i < 10; ++i) {
        // High times create crappy noise, not sure why but we loop -200 - 200 w to be safe
        v += a * smoothnoise(vec4(x,cos(time*.002)*200.));
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

// This function let's us jump from 2D-UV to spherical 3D-XYZ position
// The jist is that XY of UV can represent 2-Sphere angles to get a point on the sphere.
// The 2-Sphere point than gives you an XYZ normalized [-1,1].
vec3 uvTo3D(vec2 uv) {
    float theta = uv.x * 2.0 * 3.14159265359; // Longitude
    float phi = uv.y * 3.14159265359; // Latitude
    float x = sin(phi) * cos(theta);
    float y = sin(phi) * sin(theta);
    float z = cos(phi);
    // { Dev Note }
    // If you're porting this shader to a material, I strongly recommend you skip this function 
    // and just use the XYZ of your `varying vNormal` in place of the result you would get here.
    // Should be suitable for all spheres and most round geometries
    return vec3(x, y, z);
}

// returns max of a single vec3
float max3 (vec3 v) {
  return max (max (v.x, v.y), v.z);
}
void main(void)
{

    vec3 color;
        
    // We overwrite static colors -- Feel like I could get a cooler disco-mode but so far no luck
    if(discomode){
        colorA=vec3(sin(time),sin(time+7.),cos(time));
        colorB=vec3(cos(time),cos(time+7.),sin(time));
        colorC=vec3(sin(time),cos(time),sin(time+.5));
    }
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec3 pos = uvTo3D(uv); // UV => 3D for equirectangular/spherical mapping
    
    // Flow XYZ over time to create movement in our noise lookup.
    pos.y+=sin(time/5.);
    pos.x+=cos(time/5.);
    pos.z+=sin(time/5.);
    
    
    // Fractional Brownian Motion derived vec3s & float used to mix final color
    float fbmm=fbm(pos);
    vec3 q = vec3(fbmm,sin(fbmm),cos(fbmm));//vec3(fbm(pos + 0.025*time), fbm(pos), fbm(pos));
    vec3 r = vec3(fbmm,sin(fbmm),cos(fbmm));//vec3(fbm(pos + 1.0*q + 0.01*time), fbm(pos + q), fbm(pos + q));
    float v =fbm(pos + 5.0*r + time*0.005);
    

    // Color mix strategy from @kchnkrml (License Unkown) https://www.shadertoy.com/view/tltXWM
    // convert noise value into color
    // three colors: top - mid - bottom 
    // mid being constructed by three colors -- (ColorA - ColorB - ColorC) 
    vec3 col_top = vec3(1.0);
    vec3 col_bot = vec3(0.);
    // mix mid color based on intermediate results
    color = mix(colorA, colorB, clamp(r, 0.0, 1.0));
    color = mix(color, colorC, clamp(q, 0.0, 1.0));
    // calculate pos (scaling betwen top and bot color) from v
    float poss = v * 2.0 - 1.0;
    color = mix(color, col_top, clamp(poss, 0.0, 1.0));
    color = mix(color, col_bot, clamp(-poss, 0.0, 1.0));
    // clamp color to scale the highest r/g/b to 1.0
    color = color / max3(color);
      
    // create output color, increase light > 0.5 (and add a bit to dark areas)
    color = (clamp((0.4 * pow(v,3.) + pow(v,2.) + 0.5*v), 0.0, 1.0) * 0.9 + 0.1) * color;
    
    // Add in diffuse lighting 
    //float diffuse = max(0.0, dot(pos, vec3(1.0, sqrt(0.5), 1.0)));
    //float ambient = 0.1;
    //color *= clamp((diffuse + ambient), 0.0, 1.0);

    glFragColor = vec4(color,1.0);
}
