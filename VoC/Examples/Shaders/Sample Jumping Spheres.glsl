#version 420

// original https://www.shadertoy.com/view/3dcXD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float CellSize = 6.0;
float HalfCellSize = 3.0;

const int RayMarchingStep = 50;
const float epsilon = 0.01;

float noise(vec2 p ){
    return fract(sin(p.x*125.+p.y*412.)*5341.);
}

float dist2Sphere(vec3 p ){
    vec2 id = vec2(floor(p.x/6.0),floor(p.z/6.0));
    vec3 spherePos = vec3(id.x * CellSize + HalfCellSize ,noise(vec2(id.x+23.4,id.y+37.2))*14.*sin(time+length(id)) ,id.y * CellSize + HalfCellSize );
    
    float pulse = 0.4 + sin(time+id.x*52.+id.y*41.);
    float radius = 1.2 + pulse;
    return length( p - spherePos ) - radius ;
}

float dist2Plane(vec3 p ){
    float height = -10.;
    return p.y - height;
}

float raymarching(vec3 ro ,vec3 rd ){
    float depth = 0.0;
    rd = normalize(rd);
    for(int i=0;i<RayMarchingStep;i++){
        float dist = dist2Sphere(ro + depth * rd );
        dist = min(dist ,dist2Plane(ro + depth * rd ));

        if(dist < epsilon)
            break;
        depth = depth + min(dist,2.0);
    }
    return depth;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;

    vec3 ro = vec3(-2.0 + 100.*sin(time*0.2) ,14.0 ,-2.0 + 100.*cos(time*0.1));
    vec3 lookAt = vec3(8.0,0.0,8.0);
    
    float zoom = 0.5;
    
    vec3 front = normalize(lookAt - ro);
    vec3 right = cross(vec3(0.0,1.0,0.0),front);
    vec3 up = cross(front ,right );
    
    vec3 rd = normalize(front * zoom + right * uv.x + up * uv.y) ;
    
    float dist = raymarching(ro ,rd );
    
    vec3 color = vec3(dist / 80. * vec3(0.0,0.75,0.85));

    // Output to screen
    glFragColor = vec4(color,1.0);
}
