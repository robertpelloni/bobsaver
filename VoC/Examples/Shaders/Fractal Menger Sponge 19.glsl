#version 420

// original https://www.shadertoy.com/view/wstBz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_MENGER 6
#define MAX_MARCHES 100
#define THRESHOLD 0.001

struct Square {
    vec2 pos;
    float size;
};
    
struct Sponge {
    float size;
    vec3 pos;
    int level;
};
  
vec3 rotateX(vec3 vec, float theta) {
    float s = sin(theta), c = cos(theta);
    float y = c * vec.y - s * vec.z, z = s * vec.y + c * vec.z;
    
    return vec3(vec.x, y, z);
}
vec3 rotateY(vec3 vec, float theta) {
    float s = sin(theta), c = cos(theta);
    float x = c * vec.x + s * vec.z, z = -s * vec.x + c * vec.z;
    
    return vec3(x, vec.y, z);
}
vec3 rotateZ(vec3 vec, float theta) {
    float s = sin(theta), c = cos(theta);
    float x = c * vec.x - s * vec.y, y = s * vec.x + c * vec.y;
    
    return vec3(x, y, vec.z);
}

vec3 cube_norm(vec3 pos, vec3 vertex, float size) {
    vec3 normals[] = vec3[] (
        vec3(0, 0, -1),
        vec3(0, 0, 1),
        vec3(0, -1, 0),
        vec3(0, 1, 0),
        vec3(-1, 0, 0),
        vec3(1, 0, 0)
    );
    
    vec3 projected[] = vec3[] (
        vec3(pos.xy, vertex.z),
        vec3(pos.xy, vertex.z + size),
        vec3(pos.x, vertex.y, pos.z),
        vec3(pos.x, vertex.y + size, pos.z),
        vec3(vertex.x, pos.yz),
        vec3(vertex.x + size, pos.yz)
    );
    
    vec3 norm;
    float d = 10000.;
    
    for (int i = 0; i < 6; i++) {
        vec3 loc = pos - projected[i];
        float ld = length(loc);
        if (ld < d) {
            norm = normals[i];
            d = ld;
        }
    }
    
    return norm;
}

float sdf(vec2 pos, Square square, out vec2 normal) {
    float s = length(pos - min(max(pos, square.pos),
                               square.pos + square.size));

    vec2 edges[] = vec2[4](
        vec2(pos.x, square.pos.y),
        vec2(pos.x, square.pos.y + square.size),
        vec2(square.pos.x, pos.y),
        vec2(square.pos.x + square.size, pos.y)
    );
    
    vec2 normals[] = vec2[4](
        vec2(0, 1),
        vec2(0, -1),
        vec2(1, 0),
        vec2(-1, 0)
    );

    float d = 10000.;
    vec2 n;
    for (int i = 0; i < 4; i++) {
        vec2 norm = pos - edges[i];
        float len = length(norm);

        if (len < d) {
            d = len;
            n = normals[i];
        }
    }

    normal = n;
    
    if (s == 0.) {
        return -d;
    }
    
    return s;
}

float sdf(vec3 pos, Sponge sponge, out bool is_interior, out vec3 normal) {
    int level = sponge.level;
    float max_size = sponge.size;
    vec3 vertex = sponge.pos;
    
    vec3 contained = min(max(pos, vertex), vertex + max_size);
    
    vec3 norm = pos - contained;
    float d = length(norm);
   
    bool interior = false;
    
    for (int i = 0, size = 1; i < level; i++, size *= 3) {
        float cell_size = max_size / float(size);
        float cell_center = cell_size / 3.;
        
        // Funny story: at first I tried doing this iteratively 
        // which caused the shader to lag after level 3
        vec3 npos = mod(pos - (vertex + cell_center), cell_size);
        
        Square s;
        s.pos = vec2(0);
        s.size = cell_center;
        
        vec2 dims[] = vec2[3] ( npos.xy, npos.xz, npos.yz );
        
        for (int i = 0; i < 3; i++) {
            vec2 out_norm;
            vec3 local_norm;
            float local_d = -sdf(dims[i], s, out_norm);
            
            if (i == 0) { local_norm = vec3(out_norm, 0); }
            else if (i == 1) { local_norm = vec3(out_norm.x, 0, out_norm.y); }
            else if (i == 2) { local_norm = vec3(0, out_norm); }
            
            if (local_d > d) {
                interior = true;
                d = local_d;
                norm = local_norm;
            }
        }
    }
    
    is_interior = interior;
    normal = norm;
    
    return d;    
}

const float VIEWER_INTENSITY = .3;

vec3 get_viewer() {
    return vec3(0, 0, sin(time) * 0.5 + 1.);
}

Sponge sponge(vec3 pos, float size, int level) {
    Sponge p;
    p.size = size;
    p.pos = pos;
    p.level = level;
    return p;
}

vec3 colorAt(vec3 ray, vec3 pos) {
    Sponge s = sponge(vec3(-0.75, -0.75, 1.), 1.5, 4);
    vec3 c = vec3(0); float dist = 0.;
    
    for (int i = 0; i < MAX_MARCHES; i++) {
        vec3 n; bool inside;
        
        float d = sdf(pos, s, inside, n);
        dist += d;
        pos += d * ray;
        
        if (abs(pos.z) > 4.) { break; }
        
        if (d < THRESHOLD) {
            vec3 light = normalize(get_viewer() - pos);
            
            float intensity = VIEWER_INTENSITY / (dist*dist);
            n = (inside ? n : cube_norm(pos, s.pos, s.size)) * intensity;
            
            c = vec3(dot(light, n));
            break;
        }
    }
    
    return c;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
    
    
    vec3 ray = rotateZ(normalize(vec3(uv, 1)), time/10.);
    
    glFragColor = vec4(colorAt(ray, get_viewer()), 1.0);
}
