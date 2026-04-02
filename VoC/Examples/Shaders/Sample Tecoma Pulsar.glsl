#version 420

// original https://www.shadertoy.com/view/NtSBzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noisySine(float angle)
{
    float total = 0.0;
    for (int i = 3; i < 10; i++)
    {
        float randomValue = fract(tan(100.0*float(i) + 10.2));
        total += pow(1.14,-float(i))*sin(angle*float(i) + 6.28*randomValue + time*0.6);
        total += pow(1.14,-float(i))*sin(angle*float(i) - 6.28*randomValue - time*0.6);
    }
    total = pow(total, 2.0);
    return total;
}

vec3 dither(vec2 p)
{
    p += vec2(10.0*time, 25.0*time);
    p += vec2(14.23245, 6.876543);
    p *= vec2(2.43563,  2.786543);
    vec2 s  = vec2(p.y, p.x);
    vec2 r  = p * p;
    r += s;
    r  = fract(100.43*sin(r));
    r += sin(s*3.245);
    r += cos(p*1.24532);
    r  = fract(r);
    vec3 q = vec3(1.0) + 0.1*(2.0*vec3(r.r, (r.g + r.r)/2.0, r.g) - vec3(1));
    return q;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float m = 10.0;
    
    vec3 position      = vec3(0,0,-5);
    vec3 viewDirection = vec3(0,0,1) + vec3(gl_FragCoord.xy.x - resolution.x/2.0, gl_FragCoord.xy.y - resolution.y/2.0, 0)/resolution.x * m;
    viewDirection      = normalize(viewDirection);
    
    vec3 directionRealSpace = normalize(vec3(sin(3.0*time), 1.0, cos(3.0*time)));
    
    vec3 cameraRightRealSpace = vec3(1,0,0);
    vec3 cameraUpRealSpace    = -normalize(vec3(0,1,1));
    vec3 cameraFwdRealSpace   = normalize(vec3(0,1,-1));
    
    vec3 direction = vec3(dot(cameraRightRealSpace, directionRealSpace), dot(cameraUpRealSpace, directionRealSpace), dot(cameraFwdRealSpace, directionRealSpace));
    
    // Star
    vec3 col = vec3(0,0,0);
    col += vec3(1.0,1.0,1)  * exp((-1.0-dot(viewDirection, normalize(position)))*1000.0) * 10.0;
    col += vec3(0.6,0.75,1) * exp((-1.0-dot(viewDirection, normalize(position)))*110.0) * (1.0 + 0.9*pow(dot(direction, -normalize(position)),6.0));
    col += vec3(0.3,0.5,1)  * exp((-1.0-dot(viewDirection, normalize(position)))*16.0 ) * (1.0 + 1.3*pow(dot(direction, -normalize(position)),6.0)) * 0.8 * (1.0 + 0.03*noisySine(atan(viewDirection.y,viewDirection.x)));
    col += vec3(0.1,0.3,1)  * exp((-1.0-dot(viewDirection, normalize(position)))*1.0  ) * (1.0 + 1.5*pow(dot(direction, -normalize(position)),6.0)) * 0.1;
    
    // Jets
    vec3 jetColor = vec3(0.4, 0.6, 1.0) * 0.1;
    
    float[] radii = float[](0.880,0.900,0.910,0.915,0.920,0.925,0.930,0.935,0.940,0.945,0.960,0.970);
    
    float vd = dot(viewDirection, direction);
    float vr = dot(viewDirection, position);
    float vv = dot(viewDirection, viewDirection);
    float rd = dot(position, direction);
    float rr = dot(position, position);
    
    for (int i = 0; i < radii.length(); i++)
    {
        float a = radii[i];
        float intensity = 1.0;
        
        float inSqrt = (2.0*(vd*rd - vr*a*a))*(2.0*(vd*rd - vr*a*a))-4.0*(vd*vd-a*a*vv)*(rd*rd-a*a*rr);
        if (inSqrt > 0.0)
        {
            float distA = (-(2.0*(vd*rd - vr*a*a))-sqrt(inSqrt))/(2.0*(vd*vd-a*a*vv));
            float distB = (-(2.0*(vd*rd - vr*a*a))+sqrt(inSqrt))/(2.0*(vd*vd-a*a*vv));
            bool amInsideJet = rd*rd/rr > a*a;
            bool lookingAlongJet = vd*vd > a*a;
            bool jetIsBackwards = distA < 0.0;

            if (!amInsideJet && !lookingAlongJet && !jetIsBackwards)
            {
                float pos1 = pow(dot(distA*viewDirection + position, direction),2.0);
                float pos2 = pow(dot(distB*viewDirection + position, direction),2.0);
                
                intensity = -dot(normalize((distA + distB)*viewDirection/2.0 + position), viewDirection)+1.3;

                col += abs((1.0/pos1 - 1.0/pos2)/vd)*jetColor*intensity;
            }
            if (amInsideJet && !lookingAlongJet)
            {
                distB = 0.0;

                float pos1 = pow(dot(distA*viewDirection + position, direction),2.0);
                float pos2 = pow(dot(distB*viewDirection + position, direction),2.0);
                
                intensity = -dot(normalize((distA + distB)*viewDirection/2.0 + position), viewDirection)+1.3;

                col += abs((1.0/pos1 - 1.0/pos2)/vd)*jetColor*intensity;
            }
            if (!amInsideJet && lookingAlongJet)
            {
                float pos1 = pow(dot(distB*viewDirection + position, direction),2.0);
                
                intensity = -dot(normalize((1000.0 + distB)*viewDirection/2.0 + position), viewDirection)+1.3;

                col += abs((1.0/pos1)/vd)*jetColor*intensity;
            }
            if (amInsideJet && lookingAlongJet)
            {            
                float pos1 = pow(dot(distA*viewDirection + position, direction),2.0);
                float pos2 = pow(dot(  0.0*viewDirection + position, direction),2.0);
                
                intensity = -dot(normalize((distA + 0.0)*viewDirection/2.0 + position), viewDirection)+1.3;

                col += abs((1.0/pos1 - 1.0/pos2)/vd)*jetColor*intensity;

                if (vr < 0.0)
                {
                    float pos1 = pow(dot(distB*viewDirection + position, direction),2.0);
                    intensity = -dot(normalize((1000.0 + distB)*viewDirection/2.0 + position), viewDirection)+1.3;

                    col += abs((1.0/pos1)/vd)*jetColor*intensity;
                }
            }
        }
    }
    
    col*= dither(gl_FragCoord.xy);
    
    col = tanh(2.5*col);
    // Output to screen
    glFragColor = vec4(col,1.0);
}
