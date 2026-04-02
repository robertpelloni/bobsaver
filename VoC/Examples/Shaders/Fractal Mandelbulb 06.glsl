#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sphereDst(vec3 p, vec3 center, float radius)
{
    return length(center - p) - radius;
}

float cubeDst(vec3 p, vec3 pos, vec3 dimensions)
{
    vec3 d = abs(p - pos) - dimensions;
    
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

vec2 mandelbulbDst(vec3 p, float power)
{
    vec3 z = p;
    float dr = 1.0;
    float r = 0.0;
    
    int it = 0;
    
    for(int i = 0; i < 200; ++i)
    {
        r = length(z);
        if(r > 2.0) break;
        
        float theta = asin(z.z / r);
        float phi = atan(z.y, z.x);
        dr = pow(r, power - 1.0) * power * dr + 1.0;
        
        float zr = pow(r, power);
        theta *= power;
        phi *= power;
        
        z = vec3(cos(theta) * cos(phi), sin(phi) * cos(theta), sin(theta)) * zr;
        z += p;
        
        it = i;
    }
    
    return vec2(0.5 * log(r) * r / dr, float(it));
}

float sub(float d1, float d2)
{
    return max(d1, -d2);
}

vec2 calcDst(vec3 p)
{    
    vec2 result = mandelbulbDst(p, 8.0);
    
    return result;
}

vec3 calcNormal(vec3 p)
{
    float delta = 0.001;
    vec3 v;
    v.x = calcDst(p + vec3(delta, 0.0, 0.0)).x - calcDst(p + vec3(-delta, 0.0, 0.0)).x;
    v.y = calcDst(p + vec3(0.0, delta, 0.0)).x - calcDst(p + vec3(0.0, -delta, 0.0)).x;
    v.z = calcDst(p + vec3(0.0, 0.0, delta)).x - calcDst(p + vec3(0.0, 0.0, -delta)).x;
    return normalize(v);
}

void main( void ) {

    vec2 pos = (( gl_FragCoord.xy / resolution.xy ) - 0.5) * 2.0;
    pos.x *= resolution.x / resolution.y;

    vec3 color = vec3(0.0, 0.0, 0.0);
    
    vec3 cameraPos = vec3(2.0 * sin(time / 4.0), 0.0, 2.0 * cos(time / 4.0));
    
    vec3 up = normalize(vec3(0.0, 1.0, 0.0));
    vec3 lookAt = normalize(vec3(0.0, 0.0, 0.0) - cameraPos);
    vec3 right = normalize(cross(up, lookAt));
    
    vec3 cameraDir = normalize(pos.x * right + pos.y * up + lookAt);
    
    vec3 p = cameraPos;
    
    vec3 lightPos = vec3(2.0, 4.0, -2.0);
    
    for(int i = 0; i < 100; ++i)
    {
        vec2 dstIt = calcDst(p);
        
        p += cameraDir * dstIt.x;
        
        if(dstIt.x < 0.001)
        {
            vec3 normal = calcNormal(p);
            
            vec3 lightDir = normalize(p - lightPos);
            
            float diffuseAmt = dot(lightDir, -normal);
            
            float fI = dstIt.y + float(i) + 50.0;
            
            if(diffuseAmt > 0.0)
            {
                color.x = (-cos(fI * 0.025) + 1.0) / 2.0;
                color.y = (-cos(fI * 0.08) + 1.0) / 2.0;
                 color.z = (-cos(fI * 0.12) + 1.0) / 2.0;
                color *= diffuseAmt;
            }
            
            break;
        }
    }

    glFragColor = vec4( color, 1.0 );

}
