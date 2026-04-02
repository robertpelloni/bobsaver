#version 420

// original https://www.shadertoy.com/view/4dS3zy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ***************************************//
// Basketball, by Kleber A Garcia, 2014 (c)
// ***************************************//

const vec4 BALL = vec4(0.0,0.0,1.0,1.4);
const vec3 LIGHT = vec3(2.0, 0.4, -0.5);
const vec3 LIGHT2 = vec3(-2.0, 0.4, 0.9);
const vec3 LIGHT3 = vec3(-20.0, 4.4, 10.3);
const vec3 FLOOR_AMB = vec3(0.65,1.4,0.5);
const vec3 CEIL_AMB = vec3(0.95,0.4,0.40);
#define PI 3.141596
#define TWO_PI (2.0*PI)
float mat(vec4 ball, vec3 pos, out int material)
{
    //try sphere first
       float dist = length(ball.xyz - pos) - ball.w;
  
    material = 0;
    
    return dist;
}
vec2 getUv(vec3 normal)
{
    vec2 xzNorm = normalize(normal.xz);
    return vec2((acos(xzNorm.x) / TWO_PI), atan( normal.y/( length(normal.xz) ) ) / TWO_PI);
}
vec3 tweakNormal(vec3 normal, float freq, float blending)
{
    vec2 uv = getUv(normal);
    float s = sin(uv.x * freq);
    float c = cos(uv.y * freq);
    normal.x += blending*s;
    normal.z += blending*c;
    return normalize(normal);
}
void pointLight(vec3 normal, vec3 pos, vec3 view, vec3 lightPos, out vec3 diffuse, out vec3 spec, float specPow)
{
    vec3 lightDir = normalize(lightPos - pos);
    diffuse = vec3(clamp(dot(lightDir, normal), 0.0, 1.0));
    
    vec3 h = reflect(-view, normal);
    float nDoth = clamp(dot(-lightDir, h), 0.0, 1.0);    
    spec = vec3(pow(nDoth, specPow));
    spec = mix(spec, vec3(pow(nDoth, 32.0)), 0.4);
    
}
void scene(vec4 ball, vec3 ray, vec3 pos, out vec3 p, out vec3 col)
{
    p = pos;
    int material = -1;
    for (int it = 0; it < 30; ++it)
    {
        int m = 0;
           float dist = mat(ball, p, m);
        if (dist < 0.001) { material = m; }
        else { p = p + dist * ray;}
    }    
    
    if (material == -1) { col = vec3(0,0,0);  }
    else if (material == 0)
    {
        vec3 normal = normalize(p - ball.xyz);
        
        vec3 alb = vec3(0.4, 0.08, 0.0);
        vec3 stripsAlb =vec3(0.01,0.01,0.01); 
        float isStrips = 0.0;
        if (
            (normal.x < 0.03 && normal.x > -0.03) || 
            (normal.y < 0.03 && normal.y > -0.03) ||
            abs(normal.x) > (0.1 + 2.0*pow(normal.y,2.0)) && abs(normal.x) < (0.2+ 2.0*pow(normal.y,2.0))) { isStrips = 1.0; }
        vec3 occ = vec3(1.0 - pow(clamp(-p.y, 0.0, 1.0), 4.0));
        float nDotv = dot(normal, -ray);
        float fresnel = clamp(0.4 + pow((1.0 - clamp(nDotv, 0.0, 1.0)), 9.0), 0.0, 1.0);
        float roughness = 2.0;
        float specForce = 1.0;
        normal = mix(tweakNormal(tweakNormal(normal,3000.0,0.2), 100.0, 0.05), normal, pow(clamp(isStrips+(1.0 - clamp(nDotv, 0.0, 1.0)),0.0,1.0),0.5));
        float camSpec = 0.2*clamp(pow(clamp(nDotv, 0.0, 1.0), 1.0), 0.0, 0.3);
        nDotv = dot(normal, -ray);
        alb = mix(alb, stripsAlb, isStrips);
        
        roughness = mix(roughness, 46.0, isStrips);
        specForce = mix(specForce, 1.5, isStrips);

        vec3 diffuse = vec3(0);
        vec3 spec = vec3(0);
        pointLight(normal, p, ray, LIGHT, diffuse, spec, roughness);
        vec3 diffuse2 = vec3(0);
        vec3 spec2 = vec3(0);
        pointLight(normal, p, ray, LIGHT2, diffuse2, spec2, roughness);
        diffuse += diffuse2;
        spec += spec2;
        pointLight(normal, p, ray, LIGHT3, diffuse2, spec2, roughness);
        diffuse += diffuse2;
        spec += spec2;
        vec3 amb = mix(FLOOR_AMB, CEIL_AMB, clamp(2.0*p.y,0.0,1.0));
        col = alb*(occ*diffuse + amb) + occ*specForce*(spec+camSpec)*fresnel;//spec + alb * (clamp(dot(normal, lightDir),0.0,1.0) + occ*AMB) + occ*0.4*pow((1.0 - clamp(dot(normal, -ray), 0.0, 1.0)), 9.0);

    }
    
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec2 screen = uv * 2.0 - 1.0;
    screen.x *= resolution.x / resolution.y;
    vec3 target = vec3(screen.x, screen.y, 0.0);
    float bounce = pow(0.5*sin(time * 10.0) + 0.5 ,0.4);
    vec4 ball = vec4(BALL.xyz + vec3(0,bounce*1.0,1.0), BALL.w);
     vec3 cam = vec3(0,0,-5.0);
    vec3 ray = normalize(target - cam);
    vec3 dist = cam - ball.xyz;
    float s = sin(time);
    float c = cos(time); 
    ray = vec3(ray.x*c + ray.z*s, ray.y, ray.x *(-s) + ray.z*c);
    dist = vec3(dist.x*c + dist.z*s, dist.y, dist.x * (-s) + dist.z*c);
    
    cam = dist + ball.xyz;

    vec3 col = vec3(0,0,0);
    vec3 p = vec3(0,0,0);
    scene(ball,ray, cam, p, col);
   
    
    glFragColor = vec4(col, 1.0);
}
