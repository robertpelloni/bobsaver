#version 420

// original https://www.shadertoy.com/view/std3Wn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson (Plento)

// An endless weaving highway, with no exits. Mouse controls zoom.

#define R resolution.xy
#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)
#define ss(a, b, x) smoothstep(a, b, x)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

#define w_scale 5.
#define car_size vec2(0.07, 0.1)

// Dave Hoshkin
float hash12(vec2 p){
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float hsh(vec2 p){
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
// Standard perlin
float perlin(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = hsh(i);
    float b = hsh(i+vec2(1., .0));
    float c = hsh(i+vec2(0. ,1 ));
    float d = hsh(i+vec2(1., 1. ));
    
    vec2 u = smoothstep(0., 1., f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// box sdf
float box( in vec2 p, in vec2 b, float r){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0) - r;
}

// is a cell be flipped or not
bool flipped(vec2 id){
    float rnd = hash12(id*200.);
    if(rnd > .5) return true;
    
    return false;
}

vec3 car(vec3 col, vec2 uv, vec2 uid){
    uv.y *= .6; // stretch in direction of travel so they have more room to move in their cell
    
    float spd = time*.1;
    
    // Repeated uvs for cars (We only draw one)
    vec2 cm = vec2(0., spd );
    vec2 cv = fract((uv-cm)*w_scale*2.)-0.5;
    vec2 id = floor((uv-cm)*w_scale*2.);
    float idc = floor((uv.x-cm.x)*w_scale);
    
    // Switch direction "randomly"
    if(cos(idc*2.) > 0.){
        cm = vec2(0., -spd );
        cv = fract((uv-cm)*w_scale*2.)-0.5;
        id = floor((uv-cm)*w_scale*2.);
    }
    
    if(int(id.y) % 7 == 0) return col; // Leave some cells empty
    
    // Make cars move down road in somewhat non uniform way
    float t = id.y*114. + id.x*116.;
    vec2 p = vec2(.0, .3*cos(time*1. + t));
    
    // Adjust car position based on side of road
    if(int(id.x) % 2 == 0) p.x -= .2; 
    else p.x += .2;
    
    cv += p;
    float cars = ss(.01, .0, box(cv, car_size, .03)); // Car mask
    
    // Car color
    float ct = (id.x*3. + id.y*5.);
    vec3 carCol = .5+.26*cos(vec3(4., 2., 1.)*ct + vec3(3., 4., 7.));
    carCol *= max(ss(-.1, .21, abs(cv.y + .07)), .45);
    carCol += .16*ss(0.055, 0.01, abs(cv.y));
    
    // Randomly add some variation
    if(cos(ct) > 0.){
        carCol *= max(abs(cos(ct)), .6);
        carCol = mix(carCol, .6*vec3(.75, .85, .99), .7*ss(.3, .2, abs(cv.y*2. - .38)));
    }
   
    // Shadow under car
    float shdw = max(ss(-.08, .08, box(cv-vec2(0., .01), car_size+vec2(.015, .01), .03)), .3);
    
    return mix(col * shdw, carCol, cars) + vec3(0., 0., 0.);
}

vec3 road(vec2 uv, float y){
    float rd = ss(.02, .00, abs(uv.x)); // road mask
    rd *= ss(.25, .35, abs(fract(y*14.)-.5)); // road line
    float bdg = ss(.35, .37, abs(uv.x)); // bridge mask
    float shdw = ss(.49, .18, abs(uv.x)); // bridge shadow
    
    float nse = perlin(uv*45.); // perlin noise
    float rc = clamp(nse*.4, .22, .24); // road color
    float bc = clamp(nse, .46, .5); // bridge color
    return mix(shdw * mix(vec3(rc), vec3(1), rd), vec3(bc), bdg);
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    vec2 cv = uv;
    uv *= 1.2 + (.5+.5*sin(time*.3))*.9;
    
    //if(mouse*resolution.xy.z > 0.)
    //    uv *= max(0.4, (m.y+.4)*3.5);
    
    uv*=rot(-0.3);
    uv += time*.1;
   
    // Road uvs
    vec2 ruv = fract(uv*w_scale)-.5;
    vec2 id = floor(uv*w_scale);
    
    vec3 col = vec3(1);
    
    // rotate uv 90 degree based on cell
    float rnd = hash12(id*200.);
    if(flipped(id)){
        ruv = vec2(ruv.y, -ruv.x);
        uv = vec2(uv.y, -uv.x);
    }
    
    // cell containing current pixel flipped status
    bool me = flipped(id);
    
    // main color
    col = road(ruv, uv.y);
    col = car(col, uv, id);
    
    // neighbooring cells flipped status
    bool lft = flipped(id + vec2(-1., 0.));
    bool rgt = flipped(id + vec2(1., 0.));
    bool up = flipped(id + vec2(0., 1.));
    bool dwn = flipped(id + vec2(0., -1.));
    
    // Add a shadow based on surrounding cells
    if(me && !lft) col *= ss(.78, .12, (ruv.y));
    if(me && !rgt) col *= ss(.78, .12, (-ruv.y));
    if(!me && up) col *= ss(.78, .12, (ruv.y));
    if(!me && dwn) col *= ss(.78, .12, (-ruv.y));
    
    col = pow(col*1.2, vec3(1.1));
    
    // intro thingy
    float r = min(time, 3.);
    if(time < 3.) col *= ss(r, r-.01, length(cv));
    glFragColor = vec4(col,1.0);
}
