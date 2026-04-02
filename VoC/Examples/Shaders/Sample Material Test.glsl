#version 420

// original https://www.shadertoy.com/view/wtVSDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float MAX_DIST = 32.0f;
const int MAX_STEPS = 128;
const float MIN_DIST = 0.001f;
const float MAX_SSS_STEPS = 16.0f;

mat2 rotAxis( float t){
    float s = sin(t);
    float c = cos(t);
    return mat2(c,-s,s,c);
}

float map(vec3 p){
    p -= vec3(0,0,8.0f);
    float sint = sin(time*3.14*0.25)*0.25;
    p.xz *= rotAxis(time*.5);
    float times = 5.;
    float blob = length(p + vec3(sin(p.x*times)*sint, sin(p.y*times)*sint,sin(p.z*times)*sint))-1.5f;
    float sph = length(p-vec3(0,-78,0))-75.;
    
    return min(blob, sph);
}

vec3 calcNormal(vec3 p){
    vec2 e = vec2(0.001f,0.0f);
    return normalize(vec3(
            map(p + e.xyy) - map(p - e.xyy),
            map(p + e.yxy) - map(p - e.yxy),
            map(p + e.yyx) - map(p - e.yyx)));
}

void raymarch(vec3 ro, vec3 rd, out float t, out vec3 p){
    t=0.0;
    for(int i = 0; i < MAX_STEPS; i++){
        p = ro + t * rd;
        float d = map(p);
        if(d < MIN_DIST) break;
        t+=d;
        if(t > MAX_DIST) break;
    }
}

float shadowFactor(vec3 ro, vec3 rd){
    float minD = 1.;
    float t = MIN_DIST;
    for(int i = 0; i < MAX_STEPS; i++){
        float d = map(ro + rd*t);
        minD = min(minD, MAX_DIST * d/t);
        if(minD < MIN_DIST) break;
        t += clamp(d, MIN_DIST, .25);
    }
   
    return clamp(minD,0.,1.);
}

void main(void)
{
    vec4 mouse = vec4(0.0);//mouse*resolution.xy/resolution.xyxy;
    vec3 ro = vec3(0,0,2);
    vec3 rd = normalize(vec3((2.0*gl_FragCoord.xy - resolution.xy)/resolution.y, 1.5f));
    float t;
    vec3 p;
    vec3 nor = vec3(0.,0.,0.);
    
    
    vec3 col = vec3(0.,0.,0.);
    
    raymarch(ro, rd, t, p);
    
    vec3 sunCol = vec3(.95,.98,.85);
    vec3 skyCol = vec3(.25,.2,.8);
    vec3 grassCol = vec3(.3,.4,.2);
    float fresnel = clamp(1.-dot(-rd,nor),0.,1.);
    //lightByMouse
    
    vec3 lightDir = normalize(vec3(.3f,.3f,.8f));
    
    //fake light for when no mouse is ever been used
    if(mouse.x < 0.01 && mouse.y < 0.01){
        mouse.x = .9;
        mouse.y = .9;
    }
    
    lightDir.xz *= rotAxis((mouse.x/2.+1.)*3.14);
    lightDir.zy *= rotAxis((mouse.y/2.+1.)*3.14 + .23f);
    
    //normal
    if(t < MAX_DIST)
        nor = calcNormal(p);
    
    //material diffuse vs specular factor
    float specF = .5f;
    float diffF = 1.-specF;
    
    //ambient top
    col += skyCol * clamp(dot(vec3(0,1,0), nor),0.0f,1.0f) * diffF;
    
    //ambient bottom
    col += grassCol * 0.5f * clamp(dot(vec3(0,-1,0), nor),0.0f,1.0f) * diffF;
        
    //soft shadow factor
    float sf = shadowFactor(p+.1*nor, lightDir);

    //diff direct
    col += sf * sunCol * clamp(dot(lightDir, nor),0.0f,1.0f)*diffF;
    
    //spec direct
    vec3 spec = sf * fresnel * sunCol * clamp(dot(lightDir, reflect(rd, nor)),0.,1.);
    
    vec3 sssCol = vec3(0.83,.48,0.75);
    if(t < 32.)//if its a solid object
    {
        if(p.y>-2.){//if it's the upper object
            //SSS
            rd = refract(rd, nor, 1.0/1.5);
            float sssStep = 0.;
            float sssT = .1;
            rd = -lightDir;
            for(float i = 0.; i < MAX_SSS_STEPS; i++){
                sssStep += map(p + sssT*rd);
                sssT += .1;
            }
            float sssCont = 1.-sssStep/MAX_SSS_STEPS;
            sssCont *= sssCont;
            sssCont = clamp(sssCont,0.,1.);

            col += vec3(sssCont,sssCont,sssCont) * sssCol * sunCol;
            //kind of real looking specular shine
            col += spec*spec*specF;
        }
        else {
            //the floor has a very unreal art directed specular shine
            col += spec * spec;
        }
    }
    else{
        //cool background radial gradients
        col += vec3(.7,.3,.8) * clamp(dot(-lightDir,rd), 0.,1.)*3.;
        col += spec * spec;
        t = 32.;
    }
    
    //contrast color grading
    col=mix(col,col*col*col,.75);
    
    //uniform color grading
    col += vec3(.1,.3,.45)*.35;
    
    //depth... just for postprocessing if i feel like im going to do focus lens VFX or something
    float depth = t/MAX_DIST;
    
    glFragColor = vec4(col,depth);
}
