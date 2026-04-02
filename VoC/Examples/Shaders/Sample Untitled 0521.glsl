#version 420

// original https://www.shadertoy.com/view/WlVSWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void pR(inout vec2 p, float a) {
    p = cos(a) * p + sin(a) * vec2(p.y, - p.x);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sphere(vec3 pos, float radius) {
    return length(pos) - radius;
}
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float map(float v, float a, float b, float x, float y) {
    float n = (v - a) / (b - a);
    return x + n * (y - x);
}

float ground(vec3 pos) {
    return pos.y;
    
}

float scene(vec3 pos) {
    
    vec3 i = floor(pos / 0.5);
    
    vec3 pos1 = pos;
    pos1.xz = mod(pos1.xz, 0.5) - 0.25;
    pos1.y += .1 + sin(time + random(i.xz) * 6.2) * .1;
    float s1 = sphere(pos1, 0.05);
    
    vec3 pos1b = pos;
    pos1b.xz = mod(pos1b.xz, 0.5) - 0.25;
    pos1b.y += .1 + sin(time + random(i.xz) * 6.2) * .2;
    pos1b.x +=  sin(time + random(i.xz+1.0) * 6.2) * .05;
    pos1b.z +=  sin(time + random(i.xz+2.0) * 6.2) * .05;
    float s1b = sphere(pos1b, 0.02);
    
    s1 = smin(s1, s1b, .15);
    
    
    
    vec3 pos2 = pos;
    pos2.y += 300.0 + 0.1;
    pos2.z -= 1.0;
    float s2 = sphere(pos2, 300.0);
    
    return smin(s1, s2, 0.15);
}

vec3 estimateNormal(vec3 pos) {
    
    return normalize(
        vec3(
            scene(pos - vec3(0.001, 0.0, 0.0)) - scene(pos + vec3(0.001, 0.0, 0.0)),
            scene(pos - vec3(0.0, 0.001, 0.0)) - scene(pos + vec3(0.0, 0.001, 0.0)),
            scene(pos - vec3(0.0, 0.0, 0.001)) - scene(pos + vec3(0.0, 0.0, 0.001))
            
        ));
    }
    
    //https://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
    // these probably have pretty bad performance
    // they are modified from iq's, but I made a lot of changes
    // to explore how they work without worrying about speed

    // float jshadow( in vec3 light, in vec3 pos)
    // {
        //     float dist = distance(light, pos);
        //     vec3 dir = normalize(pos - light);
        
        //     for( float t=.1; t<dist-.01; )
        //     {
            //         float h = scene(light + dir*t);
            //         if( h<0.001 )
            //             return 0.0;
            //         t += clamp(h, 0.01, 0.50);
        //     }
        //     return 1.0;
    // }
    
    float jsoftshadow(in vec3 light, in vec3 pos, float w)
    {
        float dist = distance(light, pos);
        vec3 dir = normalize(pos - light);
        
        float s = 1.0;
        for(float t = 0.1; t < dist - 0.1; )
        {
            float h = scene(light + dir * t);
            s = min(s, 0.5 + 0.5 * h / (w * t));
            if (s < 0.0)break;
            t += clamp(h, 0.01, 0.50);
        }
        s = max(s, 0.0);
        
        return s * s*(3.0 - 2.0 * s); // smoothstep
    }
    
    vec3 lightOrigin = vec3(-0.3, 0.6, - 0.3);
    
    vec3 trace(vec3 camOrigin, vec3 dir, out float totalDist) {
        const int maxSteps = 1024;
        vec3 ray = camOrigin;
        totalDist = 0.0;
        
        // hacky near plane clipping
        totalDist += 0.1;
        ray += totalDist * dir;
        
        for(int i = 0; i < maxSteps; i ++ ) {
            float dist = scene(ray);
            if (abs(dist) < 0.001) {
                vec3 lightDir = normalize(ray - lightOrigin);
                // this is not how falloff works!
                float lightFalloff = 2.0 - pow(length(ray - lightOrigin) * 0.5, 2.0);
                float diffuse = clamp(dot(lightDir, estimateNormal(ray)) * lightFalloff, 0.0, 1.0);
                
                float s = jsoftshadow(lightOrigin, ray, 0.02);
                diffuse *= s;
                
                vec3 ambient = vec3(0.1, 0.1, 0.2);
                return vec3(1.0, 0.8, 0.6) * diffuse + ambient;
                
            }
            totalDist += dist;
            ray += dist * dir;
        }
        
        return vec3(0.0);
    }
    
void main(void)
    
    {
        lightOrigin = vec3(sin(time * 0.7), 0.5, cos(time * 0.7));
        
        // Normalized pixel coordinates (from 0 to 1)
        vec2 uv = gl_FragCoord.xy / resolution.xy;
        uv = uv * 2.0 - 1.0;
        uv.y /= resolution.x / resolution.y;
        
        vec3 camOrigin = vec3(0.0, 0.5, - 3.0);
        vec3 rayOrigin = vec3(camOrigin.xy + uv, camOrigin.z + 3.0);
        
        
        vec3 color = vec3(0.0);
        float passes = 1.;
        float blur = .00;
        for (float pass = 0.; pass < passes; pass++){
            camOrigin.x += random(rayOrigin.xy + pass/passes) * blur;
            camOrigin.y += random(rayOrigin.xy + pass/passes - 1.0) * blur;
        
            vec3 dir = normalize(rayOrigin - camOrigin);
        
            pR(dir.yz, - 0.1);
        
            float dist;
            vec3 c = trace(camOrigin, dir, dist);
        
            float fog = clamp(map(dist, 6.0, 7.0, 1.0, 0.0), 0.0, 1.0);
            c = mix(vec3(0.0), c, fog);
            color += c;
        
        }
        
        // Output to screen
        
        glFragColor = vec4(color / passes, 1.0);
    }
