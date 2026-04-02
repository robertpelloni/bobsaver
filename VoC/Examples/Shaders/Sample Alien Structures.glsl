#version 420

// original https://www.shadertoy.com/view/MtdBD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 1 // Plop this on 2/3 for a nicer, slower image
#define MAX_STEPS 512
#define PRECISION 0.0005
#define ITERATIONS 20

struct kf
{
    float time;
    vec3 pos;
    vec3 dir;
    float rotation;
    float yOffset;
    float scale;
    vec3 offset;
    float fov;
    float fade;
    vec3 g0Pos;
    float g0Size;
    float g0Strength;
    vec3 g0c0;
    vec3 g0c1;
    float g1Strength;
    vec3 g1c0;
    vec3 g1c1;
};
    
//#define OVERRIDE_FRAME 12
//#define TIME_SKIP 100.0

kf frames[] = kf[] 
(          
    kf(0.0, vec3(1.5,-2.25, 3.5), vec3(0.0,0.0,-1.0), 0.0, 0.735, 1.75, vec3(2.8,0.5,0.025), 1.0, 3.0, 
       vec3(0.0,0.0, 1.0), 2.0,
       1.0, vec3(0.2, 0.7, 0.5), vec3(0.2, 0.5, 0.5), 
       5.0, vec3(0.0, 0.5, 0.5), vec3(0.2, 0.9, 0.0)),
    
    kf(30.0, vec3(1.65,-1.5, 4.0), vec3(0.0,5.0,0.0), 0.05, 0.735, 1.75, vec3(2.8,0.5,0.025), 0.5, 0.5, 
       vec3(0.0,0.0, 1.0), 2.0,
       0.5, vec3(0.7, 0.7, 0.0), vec3(0.0, 0.5, 0.7), 
       5.0, vec3(0.0, 0.5, 0.5), vec3(0.2, 0.9, 0.0)),
        
    //----------
    
    kf(30.0, vec3(0.0,0.0, 5.035), vec3(0.0,0.0,1.0), 0.0, 0.74, 1.8, vec3(2.8,0.5,0.0), 0.35, 0.5, 
       vec3(0.0,0.0, 5.04), 0.03, 
       2.0, vec3(1.0, 0.3, 0.1), vec3(0.9, 0.25, 0.1), 
       1.5, vec3(0.5, 0.2, 0.0), vec3(0.5, 0.95, 0.0)),
    
    kf(60.0, vec3(0.0,0.0, 4.975), vec3(1.0,1.0,0.0), 0.0, 0.74, 1.8, vec3(2.8,0.5,0.0), 1.0, 0.5, 
       vec3(0.0,0.0, 5.04), 0.01, 
       1.0, vec3(1.0, 0.5, 0.0), vec3(0.9, 0.05, 0.0), 
       1.0, vec3(0.5, 0.1, 0.0), vec3(0.5, 0.7, 0.0)),

    //----------
    
    kf(60.0, vec3(-1.10,0.0, 3.5), vec3(-1.0, 0.0,-1.0), 0.0, 0.74, 1.8, vec3(2.1,2.1,0.4), 3.0, 0.5, 
       vec3(0.0,0.0, 5.04), 0.1, 
       2.0, vec3(0.5, 0.4, 0.9), vec3(0.2, 0.5, 0.7), 
       2.0, vec3(0.73, 0.5, 0.1), vec3(0.5, 0.95, 0.3)),
    
    kf(80.0, vec3(0.0,0.0, 4.8), vec3(0.0,0.0,-1.0), 0.0, 0.74, 1.8, vec3(2.1,2.1,0.4), 1.0, 0.5, 
       vec3(0.0,0.0, 5.04), 0.1, 
       1.0, vec3(0.5, 0.4, 0.9), vec3(0.2, 0.5, 0.7), 
       10.0, vec3(0.73, 0.5, 0.1), vec3(0.5, 0.95, 0.3)),
    
    //----------   

    kf(80.0, vec3(2.5, 2.5, 0.0), vec3(0.0,0.0,1.0), 1.0, 0.74, 1.8, vec3(1.59,0.2,0.065), 1.0, 0.5, 
       vec3(0.0,0.0, 5.5), 0.1, 
       1.0, vec3(0.4, 0.78, 0.91), vec3(0.6, 0.3, 0.75), 
       4.0, vec3(0.4, 0.78, 0.91), vec3(0.6, 0.3, 0.75)),

    kf(100.0, vec3(1.5, 1.5, 0.1), vec3(-0.4,-0.3,1.0), 0.0, 0.74, 1.8, vec3(1.59,0.2,0.065), 1.0, 0.5, 
       vec3(0.0,0.0, 5.45), 0.5, 
       1.0, vec3(0.4, 0.78, 0.91), vec3(0.6, 0.3, 0.75), 
       4.0, vec3(0.4, 0.78, 0.91), vec3(0.6, 0.3, 0.75)),
    
    //----------   

    kf(100.0, vec3(0.0,0.1, 2.25), vec3(1.0,0.0,0.7), 0.0, 0.75, 1.8, vec3(2.59,0.5,0.05), 1.0, 0.5, 
       vec3(0.0,0.1, 2.25), 1.0, 
       0.5, vec3(0.7, 0.2, 0.2), vec3(0.3, 0.3, 0.9), 
       3.0, vec3(0.7, 0.2, 0.2), vec3(0.3, 0.3, 0.9)),

    kf(120.0, vec3(0.0,1.5, 2.35), vec3(1.0,-0.5,0.7), 0.0, 0.75, 1.8, vec3(2.59,0.5,0.05), 0.85, 0.5, 
       vec3(0.0,0.1, 2.25), 01.5, 
       0.5, vec3(0.2, 0.2, 0.5), vec3(0.3, 0.3, 0.9), 
       3.0, vec3(0.5, 0.2, 0.2), vec3(0.3, 0.3, 0.9)),

    //----------   

    kf(120.0, vec3(0.0,0.0, 4.0), vec3(1.0,0.0,0.0), 1.0, 1.25, 2.5, vec3(2.028,1.0,0.48), 1.0, 0.5, 
       vec3(0.0,0.0, 5.04), 0.3, 
       1.0, vec3(0.5, 0.4, 0.9), vec3(0.2, 0.5, 0.7), 
       5.0, vec3(0.73, 0.5, 0.1), vec3(0.5, 0.95, 0.3)),

    kf(150.0, vec3(0.0,1.0, 2.0), vec3(1.0,0.0,1.0), 0.0, 1.4, 3.25, vec3(4.0,0.5,0.8), 1.0, 1.0, 
       vec3(0.0,0.0, 5.04), 0.3, 
       1.0, vec3(0.5, 0.4, 0.9), vec3(0.2, 0.5, 0.7), 
       5.0, vec3(0.73, 0.5, 0.1), vec3(0.5, 0.95, 0.3)),
    
    //----------   

    kf(150.0, vec3(3.0, 3.0, 0.5), vec3(-1.0,-1.0,-1.0), 0.0, 0.64, 1.8, vec3(1.659,0.02,0.0765), 1.0, 0.5, 
       vec3(0.0,0.0, 5.04), 0.1, 
       1.0, vec3(0.5, 0.4, 0.9), vec3(0.2, 0.5, 0.6), 
       2.0, vec3(0.3, 0.5, 0.5), vec3(0.9, 0.2, 0.0)),

    kf(180.0, vec3(2.5, 2.5, 1.0), vec3(-1.0,-1.0,1.0), 0.0, 0.64, 1.8, vec3(1.659,0.02,0.0765), 1.0, 0.5, 
       vec3(0.0,0.0, 0.0), 5.0,
       0.5, vec3(0.9, 0.2, 0.0), vec3(0.3, 0.5, 0.5), 
       3.0, vec3(0.3, 0.4, 0.5), vec3(0.9, 0.2, 0.0))
);

kf interpFrames(kf a, kf b, float t)
{
      kf f;
    f.time = t;
    f.pos = mix(a.pos, b.pos, t);
    f.dir = mix(a.dir, b.dir, t);
    f.rotation = mix(a.rotation, b.rotation, t);
    f.yOffset = mix(a.yOffset, b.yOffset, t);
    f.scale = mix(a.scale, b.scale, t);
    f.offset = mix(a.offset, b.offset, t);
    f.fov = mix(a.fov, b.fov, t);
    float totalTime = b.time-a.time;
    f.fade = clamp(0.0, 1.0, min(t * (totalTime/a.fade), (1.0-t) * (totalTime/b.fade)));    
    f.g0Pos = mix(a.g0Pos, b.g0Pos, t);
    f.g0Size = mix(a.g0Size, b.g0Size, t);
    f.g0Strength = mix(a.g0Strength, b.g0Strength, t);
    f.g0c0 = mix(a.g0c0, b.g0c0, t);
    f.g0c1 = mix(a.g0c1, b.g0c1, t);    
    f.g1Strength = mix(a.g1Strength, b.g1Strength, t);
    f.g1c0 = mix(a.g1c0, b.g1c0, t);
    f.g1c1 = mix(a.g1c1, b.g1c1, t);
    return f;  
}

kf evaluateFrame()
{
    #ifdef OVERRIDE_FRAME
       return frames[OVERRIDE_FRAME];
    #endif
    float t = 0.0;
    float timeLoop = mod(time, frames[frames.length()-1].time);
    
    #ifdef TIME_SKIP
    timeLoop = mod(time + TIME_SKIP, frames[frames.length()-1].time);
    #endif
    
    int i = 0;
    for(; i < frames.length()-1; ++i)
    {
        if(timeLoop < frames[i+1].time)
        {
            float tTime = frames[i+1].time - frames[i].time;
            float tUp = timeLoop - frames[i].time;
            t = tUp / tTime;
            break;
        }
    }
    
    return interpFrames(frames[i], frames[i+1], t);
}

float map(vec3 p, kf f)
{
    p /= 2.0;
    float ov = 1.0 / 3.0;
    float r;
    int i = 0;
    while (i < ITERATIONS && dot(p, p) < 10000.0)
    {
        p.xy = abs(p.xy);
        if(p.y > p.x) p.xy = p.yx;
        p.y = f.yOffset - abs(p.y - f.yOffset);
        p.x += ov;
        if(p.z > p.x) p.xz = p.zx;
        p.x -= ov;
        p.x -= ov;
        if(p.z > p.x) p.xz = p.zx;
        p.x += ov;
        p = f.scale * (p - f.offset) + f.offset;
        r = dot(p, p);
        ++i;
    }

    return abs(length(p) - length(f.offset)) * pow(f.scale, float(-i));
}

vec3 render(in vec3 ro, in vec3 rd, in vec2 uv, kf frame)
{ 
    const float breakout = 20.0;
    
    int iteration = 0;
    float depth = 0.0;
    
    for(; iteration < MAX_STEPS; ++iteration)
    {
        float precis = PRECISION * depth;
        float dist = map(ro + rd * depth, frame);
        
        if(dist < precis || depth > breakout) 
        {
            break;
        }
        depth += dist;
    }
    
    vec3 pos = ro + depth * rd;
    
    float glow0 = float(iteration) / float(MAX_STEPS);
    glow0 = clamp(pow(glow0 * 3.0, 1.0), 0.0, 1.0);
    float glow1 = pow(glow0, 3.20);
    
    float distFromPoint = clamp(0.0, 1.0, distance(pos, frame.g0Pos) / frame.g0Size);
    
    vec3 glowColor0 = mix(frame.g0c0, frame.g0c1, clamp(distFromPoint, 0.0, 1.0));
    vec3 col = glowColor0 * glow0 * frame.g0Strength;
    
    vec3 glowColor1 = mix(frame.g1c0, frame.g1c1, clamp(0.0, 1.0, uv.y/2.0));
    col.rgb += glowColor1 * glow1 * frame.g1Strength;
    
    return col;
}

void main(void)
{
    kf frame = evaluateFrame();
    
    vec3 cSum = vec3(0.0, 0.0, 0.0);
    
    for(int i = 0; i < AA; ++i)
    {
        for(int j = 0; j < AA; ++j)
        {
            vec2 o = vec2(float(i),float(j)) / float(AA) - 0.5;
            vec2 p = (-resolution.xy + 2.0 * (gl_FragCoord.xy+o)) / resolution.y;
            vec3 ro = frame.pos;
            float cr = frame.rotation;
            vec3 cw = normalize(frame.dir);
            vec3 cp = vec3(sin(cr), cos(cr), 0.0);
            vec3 cu = normalize(cross(cw ,cp));
            vec3 cv = normalize(cross(cu, cw));
            mat3 ca = mat3(cu, cv, cw);
            vec3 rd = ca * normalize(vec3(p.xy, 2.0 * frame.fov));

            cSum += render(ro, rd, p, frame);
        }
    }
    
    cSum /= float(AA*AA);
    
    #ifndef OVERRIDE_FRAME
    cSum.rgb *= frame.fade;
    #endif

    cSum = pow(cSum, vec3(0.4545));
    cSum = cSum * 1.2 - 0.1;
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv *=  1.0 - uv.yx;
    
    cSum *= clamp(0.0, 1.0, pow(uv.x*uv.y * 5.0, 0.1));
    
    float n = 1.0;//texture(iChannel0, gl_FragCoord.xy/iChannelResolution[0].xy).r;
    cSum.rgb += mix(-3.0 / 255.0, 3.0 / 255.0, n);

    glFragColor = vec4(cSum, 1.0);
}

