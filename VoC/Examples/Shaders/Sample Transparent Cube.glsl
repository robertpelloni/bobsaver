#version 420

// original https://www.shadertoy.com/view/NdGBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926
#define REFRACTIVEINDEX 1.6
#define SPHERESCALE 2.
#define SPHERECOLOR vec4(1, 0.8, 0.2, 0)

vec4 Color(vec3 direction)
{
    return vec4(exp(2.*(dot(direction, normalize(vec3(0.2,0.2,1))) - 1.)));
}

vec4 SphereColor(vec3 direction, vec3 normal)
{
    return tanh(0.3*SPHERECOLOR*vec4(clamp(dot(normal, normalize(vec3(0.2,0.2,1))),0.,1.) + 2.*exp(4.*(dot(direction, normalize(vec3(0.2,0.2,1))) - 1.))));
}

float MinDistFromPoint(vec3 position, vec3 direction, vec3 point)
{
    return length(cross(direction, point-position));
}

void main(void)
{
    float theta = (mouse.x*resolution.x - resolution.x / 2.) / resolution.y * PI;
    float phi   = (mouse.y*resolution.y - resolution.y / 2.) / resolution.y * PI;

    // CAMERA
    vec3 iCameraFwd     = vec3(sin(theta)*cos(phi),sin(phi),cos(theta)*cos(phi));
    vec3 iCameraUp      = vec3(-sin(theta)*sin(phi),cos(phi),-cos(theta)*sin(phi));
    vec3 iCameraRight   = normalize(cross(iCameraUp, iCameraFwd));
    
    vec3 iCameraPosition      = -5.*iCameraFwd;
    
    float m = 2.0;
    
    vec3 iViewDirection = iCameraFwd + ((gl_FragCoord.xy.x - resolution.x/2.0) * iCameraRight + (gl_FragCoord.xy.y - resolution.y/2.0) * iCameraUp) / resolution.x * m;
    iViewDirection      = normalize(iViewDirection);
    
    // LIST OF SPHERES (you can change this but make sure to change the number of iterations later on if you change the length)
    vec4 spheres[10] = vec4[10]( 
    vec4(0.5994,-0.047,-0.2684,0.0037),
    vec4(-0.3751,0.4339,-0.323,0.0059),
    vec4(0.1887,0.561,0.4849,0.0013),
    vec4(-0.5643,0.3423,0.3824,0.0016),
    vec4(-0.4036,-0.5562,-0.3511,0.0015),
    vec4(-0.7544,0.1479,-0.0931,0.0008),
    vec4(0.3231,-0.2607,0.3537,0.0064),
    vec4(0.7145,0.1231,-0.4334,-0.0026),
    vec4(-0.5673,0.1445,0.5225,0.0009),
    vec4(-0.2407,0.5556,-0.4704,0.0022));
    
    // SORTING FACES
    float distXP =  (1.-iCameraPosition.x)/iViewDirection.x;
    float distYP =  (1.-iCameraPosition.y)/iViewDirection.y;
    float distZP =  (1.-iCameraPosition.z)/iViewDirection.z;
    
    float distXM = (-1.-iCameraPosition.x)/iViewDirection.x;
    float distYM = (-1.-iCameraPosition.y)/iViewDirection.y;
    float distZM = (-1.-iCameraPosition.z)/iViewDirection.z;
    
    vec3 faceList[6] = vec3[6]( vec3(1,0,0), vec3(0,1,0), vec3(0,0,1),
                                vec3(-1,0,0),vec3(0,-1,0),vec3(0,0,-1));

    float distList[6] = float[6]( distXP, distYP, distZP,
                                  distXM, distYM, distZM);
    
    for (int n = 0; n < 5; n++)
    {
        for (int i = 0; i < 5; i++)
        {
            if (distList[i] > distList[i+1])
            {
                vec3 c        = faceList[i];
                faceList[i]   = faceList[i+1];
                faceList[i+1] = c;
                
                float r       = distList[i];
                distList[i]   = distList[i+1];
                distList[i+1] = r;
            }
        }
    }
    
    vec3 position = iCameraPosition;
    vec3 direction = iViewDirection;
    
    glFragColor = vec4(0);
    vec3 normal = vec3(0);
    bool hitSphere = false;
    
    // IF IT HITS THE CUBE, DO STUFF
    if (length(faceList[0]+faceList[1]+faceList[2]) >= sqrt(3.))
    {
        position += direction * distList[2];
        normal = faceList[2];
        
        // SPECULAR REFLECTION OFF THE CUBE
        float R0 = (1.-REFRACTIVEINDEX)/(1.+REFRACTIVEINDEX);
        R0 *= R0;
        float d = -dot(normal, direction);
        glFragColor += 1.4*Color(direction + 2.*normal*d)*(R0 + (1.-R0)*pow(abs(1.-d), 5.));
        
        
        // REFRACTION ON THE SURFACE OF THE CUBE
        vec3 flattened = normalize(direction - dot(normal, direction)*normal);
        float snell = (1./REFRACTIVEINDEX)*(length(cross(direction, normal)));
        direction = snell*flattened - sqrt(1.-snell*snell)*normal;
        
        // SORTING THE SPHERES
        for (int n = 0; n < 9; n++)
        {
            for (int i = 0; i < 9; i++)
            {
                float disti  = distance(position, spheres[i].xyz);
                float distip = distance(position, spheres[i+1].xyz);
                if (disti > distip)
                {
                    vec4 c        = spheres[i];
                    spheres[i]    = spheres[i+1];
                    spheres[i+1]  = c;
                }
            }
        }
        
        // CHECKING IF IT HITS ANY SPHERES (and doing lighting if it does)
        for (int i = 0; i < 10; i++)
        {
            float minDist = MinDistFromPoint(position, direction, spheres[i].xyz);
            if (minDist < sqrt(spheres[i].w)*SPHERESCALE)
            {
                hitSphere = true;
                flattened = -cross(cross(direction, spheres[i].xyz-position), normalize(spheres[i].xyz-position))/(sqrt(spheres[i].w)*SPHERESCALE);
                normal    = flattened - direction*sqrt(1.-length(flattened));
                glFragColor += 4.*SphereColor(reflect(direction, normal), normal);
                break;
            }
        }
        
        // RE-SORTING CUBE FACES FOR EXIT
        float distXP =  (1.-position.x)/direction.x;
        float distYP =  (1.-position.y)/direction.y;
        float distZP =  (1.-position.z)/direction.z;

        float distXM = (-1.-position.x)/direction.x;
        float distYM = (-1.-position.y)/direction.y;
        float distZM = (-1.-position.z)/direction.z;

        vec3 faceList[6] = vec3[6]( vec3(1,0,0), vec3(0,1,0), vec3(0,0,1),
                                   vec3(-1,0,0),vec3(0,-1,0),vec3(0,0,-1));

        float distList[6] = float[6]( distXP, distYP, distZP,
                                      distXM, distYM, distZM);

        for (int n = 0; n < 5; n++)
        {
            for (int i = 0; i < 5; i++)
            {
                if (distList[i] > distList[i+1])
                {
                    vec3 c        = faceList[i];
                    faceList[i]   = faceList[i+1];
                    faceList[i+1] = c;

                    float r       = distList[i];
                    distList[i]   = distList[i+1];
                    distList[i+1] = r;
                }
            }
        }
        
        // REFRACTION AGAIN
        position += direction * distList[3];
        normal = faceList[3];
        flattened = normalize(direction - dot(normal, direction)*normal);
        snell = (REFRACTIVEINDEX)*(length(cross(direction, normal)));
        
        // IF NO INTERNAL REFLECTION, THE RAY EXITS. ELSE, IT REFLECTS ONCE
        if (snell < 1.)
        {
            direction = snell*flattened + sqrt(1.-snell*snell)*normal;
        }
        else
        {
            // REFLECTION
            direction -= 2.*normal*dot(normal, direction);
            
            // SORTING SPHERES AGAIN
            for (int n = 0; n < 9; n++)
            {
                for (int i = 0; i < 9; i++)
                {
                    float disti  = distance(position, spheres[i].xyz);
                    float distip = distance(position, spheres[i+1].xyz);
                    if (disti > distip)
                    {
                        vec4 c        = spheres[i];
                        spheres[i]    = spheres[i+1];
                        spheres[i+1]  = c;
                    }
                }
            }
            
            // IF IT HASN'T ALREADY HIT A SPHERE, IT CHECKS IF IT DOES THIS TIME
            if (!hitSphere)
            {
                for (int i = 0; i < 10; i++)
                {
                    float minDist = MinDistFromPoint(position, direction, spheres[i].xyz);
                    if (minDist < sqrt(spheres[i].w)*SPHERESCALE)
                    {
                        hitSphere = true;
                        flattened = -cross(cross(direction, spheres[i].xyz-position), normalize(spheres[i].xyz-position))/(sqrt(spheres[i].w)*SPHERESCALE);
                        normal    = flattened - direction*sqrt(1.-length(flattened));
                        glFragColor += 4.*SphereColor(reflect(direction, normal), normal);
                        break;
                    }
                }
            }
            
            // RE-SORT CUBE FACES FOR EXIT
            float distXP =  (1.-position.x)/direction.x;
            float distYP =  (1.-position.y)/direction.y;
            float distZP =  (1.-position.z)/direction.z;

            float distXM = (-1.-position.x)/direction.x;
            float distYM = (-1.-position.y)/direction.y;
            float distZM = (-1.-position.z)/direction.z;

            vec3 faceList[6] = vec3[6]( vec3(1,0,0), vec3(0,1,0), vec3(0,0,1),
                                       vec3(-1,0,0),vec3(0,-1,0),vec3(0,0,-1));

            float distList[6] = float[6]( distXP, distYP, distZP,
                                          distXM, distYM, distZM);

            for (int n = 0; n < 5; n++)
            {
                for (int i = 0; i < 5; i++)
                {
                    if (distList[i] > distList[i+1])
                    {
                        vec3 c        = faceList[i];
                        faceList[i]   = faceList[i+1];
                        faceList[i+1] = c;

                        float r       = distList[i];
                        distList[i]   = distList[i+1];
                        distList[i+1] = r;
                    }
                }
            }
            
            // REFRACTION OF EXIT RAY
            position += direction * distList[3];
            normal = faceList[3];
            flattened = normalize(direction - dot(normal, direction)*normal);
            snell = (REFRACTIVEINDEX)*(length(cross(direction, normal)));
        }
    }
    
    // IF IT HASN'T HIT ANY <OPAQUE> SPHERES, WE PAINT ON THE RIGHT BACKGROUND COLOR
    glFragColor += Color(direction)*float(!hitSphere);
}
