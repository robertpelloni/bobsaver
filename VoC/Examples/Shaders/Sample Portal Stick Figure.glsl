#version 420

// original https://www.shadertoy.com/view/MlScW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define black vec4(0)
#define white vec4(1)
#define PI radians(180.0)

#define sphere(p, r) (length(p)-r)

// ellipsoid + box from
// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float ellipsoid(vec2 p, vec2 r)
{
    return (length(p/r) - 1.0) * min(r.x,r.y);
}

float box(vec2 p, vec2 b)
{
  vec2 d = abs(p) - b;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float hash(float time, float offset)
{
    return sin(pow((2.0 + sin(floor(time) + offset)) * 7.5439, 3.153));
}

vec3 hash3(float time, vec3 offset)
{
    return vec3(
        hash(time, offset.x),
        hash(time+511.0, offset.y),
        hash(time+1773.0, offset.z)
    );
}

float bulge(float from, float to, float x)
{
    return 1.0-smoothstep(from, to, abs(x));
}

vec2 portalGuyGaze(vec2 xy, float gTime)
{
    float time = gTime / 5.187;
    float base = floor(time);
    
    vec3 gaze = vec3(0);
    for (int i=-3 ; i<=3 ; i++)
    {
        vec3 next_gaze = hash3(time, vec3(float(i)));
        float next_at = base + float(i);
        next_at += 2.0 * hash(time, float(i));
        
        gaze = mix(gaze, next_gaze, bulge(0.12, 0.2, time - next_at));
    }
    
    gaze.xy = normalize(vec2(1.0, 0.0) + 0.2 * gaze.xy);
    gaze.z = 1.0 + 0.12 * abs(gaze.z);
    
    xy.y *= gaze.z;
    xy = vec2(dot(gaze.xy, xy), dot(gaze.yx*vec2(-1,1), xy));
    xy.x *= 1.0 + abs(gaze.y);
    
    return xy;
}

float portalGuy(vec2 xy, float gTime, float walk, float bob)
{
    float time = mod(gTime * 2.0, 1.0);
    float walk1 = 0.2*(0.0+smoothstep(0.0, 0.1, time)-smoothstep(0.5, 0.6, time));
    float walk2 = 0.2*(1.0-smoothstep(0.0, 0.1, time)+smoothstep(0.5, 0.6, time));
    float r = 100.0;
    
    float ang = time*PI*2.0;
    xy.y -= (
        abs(sin(ang))
    )*0.05*walk;
    
    ang = sin(ang) * 0.05 * bob;
    vec3 turn = vec3(cos(ang), sin(ang), -sin(ang));
    xy = vec2(dot(turn.xy, xy), dot(turn.zx, xy));
    
    vec2 gazeOffset = vec2(0, 0.9);
    xy = mix(xy, portalGuyGaze(xy-gazeOffset, gTime)+gazeOffset, max(0.0, xy.y-gazeOffset.y));
    
    r = min(r, sphere(xy-vec2(0,1.6), 0.3));
    r = min(r, ellipsoid(xy-vec2(0.,1.0), vec2(0.35,0.25)));
    r = min(r, box(xy-vec2(0,0.7),vec2(0.35,0.3)));
    
    r = min(r, box(xy-vec2(0.15,0.25+walk*walk1),vec2(0.12,0.25)));
    r = min(r, box(xy-vec2(-0.15,0.25+walk*walk2),vec2(0.12,0.25)));
    return r;
}

float world(vec2 xy, float gTime)
{
    float r = 100.0;
    
    float boredom = 5.0;
    float restlessness = boredom/3.0;
    
    float sequence = gTime / boredom;
    float pos1 = 1.0 * hash(sequence, 4.0);
    float pos2 = 1.0 * hash(sequence, 5.0);
    
    float offset = restlessness * hash(sequence, 0.0);
    float time = mod(gTime, boredom) - 0.5*boredom + offset;
    float duration = abs(pos2 - pos1);
    
    duration *= 0.5;
    vec2 pos = vec2(
        pos1 + (pos2-pos1) * smoothstep(-0.05-duration, 0.05+duration, time),
        0
    );
    float walk = smoothstep(-0.05, 0.05, time+duration)-smoothstep(-0.05, 0.05, time-duration);
    float bob = smoothstep(-0.35, 0.15, time+duration)-smoothstep(-0.15, 0.15, time-duration);
    
    r = min(r, portalGuy(xy-pos, gTime, walk, bob));
    
    r = min(r, xy.y);
    r = min(r, 2.5-xy.y);
    return r;
}

#define TIME_TUNNEL
void main(void)
{
    vec2 uv = gl_FragCoord.xy - resolution.xy / 2.0;
    float scale = 3.0 / resolution.y;
    uv *= scale;
    
    float gTime = time;
    
    vec2 cam = vec2(0, -1.2);
    glFragColor = white - white * smoothstep(0.5, -0.5, world(uv-cam, gTime)/scale);
    
#ifdef TIME_TUNNEL
    float dtime = mod(time / 120.0, 2.0);
    float start = 0.0;
    if (floor(dtime) == start)
    {
        dtime -= start;
        
        float fade = pow(smoothstep(0.0, 0.05, dtime) - smoothstep(0.95, 1.0, dtime), 3.0);
        fade *= smoothstep(0.0, 120.0*0.05, time);
        
        vec3 depth = vec3(uv, 0);
        float act = 1.0;
        for (int i=0 ; i<100 ; i++)
        {
            if (world(uv-cam, gTime) < 0.0)
                break;

            depth.z += 0.5;
            gTime -= 0.1*fade;

            float ang = sin(time*0.1541)*0.2 * fade;
            vec3 turn = vec3(cos(ang), sin(ang), -sin(ang));
            ang = cos(time * 0.7785) * PI * fade;
            vec2 offset = vec2(cos(ang), sin(ang)) * fade;
            uv -= offset;
            uv = vec2(dot(turn.xy, uv), dot(turn.zx, uv)) / pow(0.9, fade);
            uv += offset;
        }

        glFragColor = vec4(vec3(log(depth.z)+1.)*0.3, 0.0);
    }
#endif
}
