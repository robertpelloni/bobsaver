#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float calcDstMandelbulb(float power, vec3 point)
{    
    vec3 z = point;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < 100; i++)
    {
        r = length(z);
        if (r > 2.0) break;

        // convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        dr = pow(r, power - 1.0) * power * dr + 1.0;
        // scale and rotate the point
        float zr = pow(r, power);
        theta = theta * power;
        phi = phi * power;
        // convert back to cartesian coordinates
        z = vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta)) * zr;
        z += point;
    }
    return 0.5 * log(r) * r / dr;
}

void main( void ) {
    
    const int iterations = 100;
    
    vec3 cameraPos = vec3(0.0, 0.0, -3.0 - sin(time));

    vec3 color = vec3(0.0, 0.0, 0.0);
    
    vec2 position = (gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
    position.x *= resolution.x / resolution.y;

    float t = 0.0;
    
    for(int i = 1; i <= iterations; i++)
    {
        float dst = calcDstMandelbulb(5.0 + cos(time), cameraPos + vec3(position, 1.0) * t);
        
        if(dst >= 0.0 && dst < 0.001)
        {
            color = vec3(0.1, 0.2, 0.4);
            
            color += vec3(i) / float(iterations);
            
            break;
        }
        
        t += dst;
    }
    
    glFragColor = vec4( color, 1.0 );

}
