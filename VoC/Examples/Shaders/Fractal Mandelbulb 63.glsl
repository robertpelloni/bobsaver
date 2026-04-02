#version 420

// original https://www.shadertoy.com/view/Ndy3zG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rotate(vec3 pos, vec2 rotation) {
    vec2 m4 = vec2(length(pos.xz), length(pos.xyz));

    vec2 angle = vec2(acos(pos.x/m4.x), asin(pos.z/m4.y));
    float l = length(pos);
    vec3 poss = pos;
    float xx = poss.x*cos(rotation.y)+poss.z*sin(rotation.y);
    float yy = poss.y;
    
    float zz = -pos.x*sin(rotation.y)+poss.z*cos(rotation.y);
    
    return vec3(xx, yy, zz);
}

vec3 fractal(vec3 coords, int iterations, float degreee, float xRot) {
    float pi = 3.1415926;
    float degree = 7.0;
    vec3 coordsMod = coords.xyz;
    for (int i = 0; i < iterations; i++) {
        vec3 UV = vec3(coordsMod.xyz);
        UV = vec3(1.0*length(UV), abs(UV.y)/UV.y*acos(UV.x/length(UV.xy))+xRot, abs(UV.z)/UV.z*asin(abs(UV.z)/length(UV)));
        coordsMod = coords.xyz+pow(UV.x, degree)*vec3(cos(degree*UV.y)*cos(degree*UV.z), sin(degree*UV.y)*cos(degree*UV.z), sin(degree*UV.z));
        
    }
    if (length(coordsMod) < 2.0) {
        return vec3(0.3, 0.5, 1.0);
        //return vec3(1.0);
    } else {
        return vec3(0.0);
    }
    
    
}

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 rayCast(vec3 dir, vec3 pos, float xRot, vec2 coord) {
    float density = 500.0;
    float anisotropy = 0.0;
    float pi = 3.1415926;
    vec3 o = vec3(0.0);
    float stepSize = 0.02;
    float lightingStepSize = 0.05;
    vec3 p = pos+dir*stepSize*rand(coord.xy);
    vec3 n = vec3(0.0);
    vec3 lightingDir = vec3(cos(-xRot+time*0.5), sin(-xRot+time*0.5), -sin(time*2.718/4.0));
    lightingDir = lightingDir/length(lightingDir);
    
    float a = dot(dir, dir);
    float b = 2.0*dot(dir, pos);
    float c = dot(pos, pos) - pow(2.0, 2.0);
    float discriminant = b*b-4.0*a*c;
    
    if (discriminant > 0.0) {
        vec3 inPos = (-b - sqrt(discriminant))/(2.0*a)*dir+pos;
        vec3 outPos = (-b + sqrt(discriminant))/(2.0*a)*dir+pos;
        p = inPos+dir*stepSize*rand(coord.xy);
        for (float j = 0.0; j < length(inPos-outPos); j += stepSize) {
            p += dir*stepSize;
            vec3 pp = p+lightingStepSize*lightingDir*rand(coord.xy);
            vec3 l = vec3(0.0);
            vec3 m;
            if (length(p) < 2.0) {
                m = fractal(p, 4, 8.0, xRot+time*0.0)*stepSize;
                o += m;
                if (length(o) > 1.0) {
                    j = 2.0 + length(pos);
                }
            } else {
                m = vec3(0.0);
            }
            if (length(m) > 0.0) {
                for (vec3 k = p; length(pp) < 2.0; pp -= lightingStepSize*lightingDir) {
                    l += fractal(pp, 4, 8.0, xRot)*stepSize;
                    if (length(l) > 1.0) {
                        pp = vec3(2.0);
                
                    }
                }
            }
            
            vec3 q = vec3(0.0);
            q.x = stepSize*m.x*density*pow(2.0, -density*stepSize*length(o.x))*pow(2.0, -density*stepSize*length(l.x));
            q.y = stepSize*m.y*density*pow(2.0, -density*stepSize*length(o.y))*pow(2.0, -density*stepSize*length(l.y));
            q.z = stepSize*m.z*density*pow(2.0, -density*stepSize*length(o.z))*pow(2.0, -density*stepSize*length(l.z));
            float cloudValAdjust = 0.3;
            float cloudVal = 0.0;
            float minV = 0.0;
            float maxV = 1.0;
            anisotropy = clamp((length(o*cloudValAdjust)/(length(o*cloudValAdjust)+1.0)-minV)/(maxV-minV), 0.0, 1.0)*-cloudVal+clamp(1.0-(length(o*cloudValAdjust)/(length(o*cloudValAdjust)+1.0)-minV)/(maxV-minV), 0.0, 1.0)*cloudVal;
            if (anisotropy >= 0.0) {
                q*=(1.0-anisotropy+pow(2.7, -anisotropy/(1.0-anisotropy)*(1.0-dot(-dir, lightingDir))));
            } else {
                q*=(1.0+anisotropy+pow(2.7, anisotropy/(1.0+anisotropy)*(1.0-dot(dir, lightingDir))));
            }
            n.x+=q.x;
            n.y+=q.y;
            n.z+=q.z;
        }
    }
    return n;
    
    //return vec3(dot(dir, lightingDir));
}

void main(void)
{
    float pi = 3.1415926;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 mouse = (mouse*resolution.xy.xy/resolution.x-0.5);
    float x = gl_FragCoord.xy.x/resolution.x-0.5;
    float y = (gl_FragCoord.xy.y-0.5*resolution.y)/resolution.x;
    
    //RayCasting
    float dof = 1.0;
    float r = 5.0;
    float s = 10.0;
    vec3 camPos = rotate(vec3(r, 0.0, 0.0), -vec2(-time*0.2, -s*(mouse.y+pi/2.0)));
    
    vec3 camDir = rotate(vec3(-1.0, dof*x, dof*y), vec2(time*0.2, s*(mouse.y+pi/2.0)));
    
    // Time varying pixel color
    vec3 col = rayCast(camDir, camPos, -s*mouse.x, gl_FragCoord.xy);
    
    //col = (log(1.+col));
    //col = clamp(col,0.,1.);
    col *= 2.0;
    col = col/(col+vec3(1.0));
    // Output to screen
    glFragColor = vec4(col,1.0);
}
