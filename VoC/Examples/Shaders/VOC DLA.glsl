#version 120

// original https://www.shadertoy.com/view/MtyGzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float pos_dist;
vec3 normal;
int sphere_hit; //which sphere did the ray hit
vec3 sphere_hit_point;

vec4 test_sphere( vec4 sphere, vec3 ray ) {
    
    vec3 r2s = ray * dot( sphere.xyz, ray );
    vec3 near2s = r2s - sphere.xyz;
    
    vec4 rgbz = vec4( 0, 0, 0, 0 );
    
    if( length( near2s ) < sphere.w ) {
        vec3 r0s = r2s - ray * sqrt(  pow( sphere.w, 2. ) - pow( length( near2s ), 2. )  );
        normal=normalize( r0s - sphere.xyz );
        sphere_hit_point=r0s;
        float l1 = 0.2-0.8*dot( ray, normal );
        vec3 c = vec3( 1, 1, 1 ) * pow( l1, 1.5 ) * ( 1.0 - smoothstep( abs(pos_dist), abs(pos_dist*1.5), sphere.z ) );
        rgbz = vec4( c, length( r0s ) );
    }
    
    return rgbz;
}
   
void main(void)
{
    float t = 0.0;//time; // uncomment for rotating display
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 ar = vec2( 1, resolution.y / resolution.x );
    
    vec3 ray = normalize( vec3( ( uv - .5 ) * ar, 1 ) );
    
    vec3 v = normalize( vec3( cos( 0.7*t ), sin ( 1.2*t ), cos( 2.0*t ) ) );
    float t2 = t + 0.05;
    vec3 dv = normalize( ( normalize( vec3( cos( 0.7*t2 ), sin ( 1.2*t2 ), cos( 2.0*t2 ) ) ) - v ) / 0.05 );
    mat3 obj2cam = mat3( v, dv, cross( v, dv ) );
    vec3 light = vec3(-20,20,-20); //light position
    vec3 ambient = vec3(0.2,0.2,0.2); //ambient light
    vec3 pos = vec3(0,0,23.4849283018016); //eye position
    pos_dist = length(pos);
    const int sphere_count=110;
    vec3 spheres[110];
    spheres[0] = vec3(-5,-3,3);
    spheres[1] = vec3(-5,-1,5);
    spheres[2] = vec3(-5,-1,6);
    spheres[3] = vec3(-5,2,-3);
    spheres[4] = vec3(-5,3,-4);
    spheres[5] = vec3(-4,-2,3);
    spheres[6] = vec3(-4,-2,4);
    spheres[7] = vec3(-4,-2,5);
    spheres[8] = vec3(-4,1,-3);
    spheres[9] = vec3(-4,1,-2);
    spheres[10] = vec3(-4,3,-3);
    spheres[11] = vec3(-3,-2,5);
    spheres[12] = vec3(-3,-1,0);
    spheres[13] = vec3(-3,-1,3);
    spheres[14] = vec3(-3,-1,4);
    spheres[15] = vec3(-3,0,-3);
    spheres[16] = vec3(-3,0,-1);
    spheres[17] = vec3(-3,2,-4);
    spheres[18] = vec3(-3,2,4);
    spheres[19] = vec3(-3,3,-4);
    spheres[20] = vec3(-2,-3,2);
    spheres[21] = vec3(-2,-3,3);
    spheres[22] = vec3(-2,-2,-2);
    spheres[23] = vec3(-2,-2,1);
    spheres[24] = vec3(-2,-2,6);
    spheres[25] = vec3(-2,-1,2);
    spheres[26] = vec3(-2,-1,5);
    spheres[27] = vec3(-2,-1,6);
    spheres[28] = vec3(-2,0,-2);
    spheres[29] = vec3(-2,0,3);
    spheres[30] = vec3(-2,1,-4);
    spheres[31] = vec3(-2,1,-2);
    spheres[32] = vec3(-2,1,3);
    spheres[33] = vec3(-2,1,4);
    spheres[34] = vec3(-2,2,-1);
    spheres[35] = vec3(-2,2,2);
    spheres[36] = vec3(-2,3,-2);
    spheres[37] = vec3(-1,-2,-2);
    spheres[38] = vec3(-1,-2,2);
    spheres[39] = vec3(-1,-1,-1);
    spheres[40] = vec3(-1,-1,0);
    spheres[41] = vec3(-1,-1,1);
    spheres[42] = vec3(-1,0,-1);
    spheres[43] = vec3(-1,0,0);
    spheres[44] = vec3(-1,0,1);
    spheres[45] = vec3(-1,0,2);
    spheres[46] = vec3(-1,0,4);
    spheres[47] = vec3(-1,1,-3);
    spheres[48] = vec3(-1,1,-1);
    spheres[49] = vec3(-1,1,0);
    spheres[50] = vec3(-1,1,1);
    spheres[51] = vec3(-1,2,4);
    spheres[52] = vec3(-1,3,-3);
    spheres[53] = vec3(0,-1,-2);
    spheres[54] = vec3(0,-1,-1);
    spheres[55] = vec3(0,-1,0);
    spheres[56] = vec3(0,-1,1);
    spheres[57] = vec3(0,0,-1);
    spheres[58] = vec3(0,0,1);
    spheres[59] = vec3(0,1,-4);
    spheres[60] = vec3(0,1,-1);
    spheres[61] = vec3(0,1,0);
    spheres[62] = vec3(0,1,1);
    spheres[63] = vec3(0,1,4);
    spheres[64] = vec3(0,1,5);
    spheres[65] = vec3(0,2,-3);
    spheres[66] = vec3(0,2,-2);
    spheres[67] = vec3(0,3,3);
    spheres[68] = vec3(1,-4,4);
    spheres[69] = vec3(1,-2,0);
    spheres[70] = vec3(1,-1,-1);
    spheres[71] = vec3(1,-1,0);
    spheres[72] = vec3(1,-1,1);
    spheres[73] = vec3(1,0,-1);
    spheres[74] = vec3(1,0,0);
    spheres[75] = vec3(1,0,1);
    spheres[76] = vec3(1,1,-4);
    spheres[77] = vec3(1,1,-1);
    spheres[78] = vec3(1,1,0);
    spheres[79] = vec3(1,1,1);
    spheres[80] = vec3(1,2,-2);
    spheres[81] = vec3(1,2,0);
    spheres[82] = vec3(1,2,2);
    spheres[83] = vec3(1,3,-3);
    spheres[84] = vec3(1,3,-2);
    spheres[85] = vec3(1,3,2);
    spheres[86] = vec3(2,-3,3);
    spheres[87] = vec3(2,-3,4);
    spheres[88] = vec3(2,-2,0);
    spheres[89] = vec3(2,-2,2);
    spheres[90] = vec3(2,-1,-2);
    spheres[91] = vec3(2,-1,2);
    spheres[92] = vec3(2,1,0);
    spheres[93] = vec3(2,2,-1);
    spheres[94] = vec3(2,4,-1);
    spheres[95] = vec3(3,-3,3);
    spheres[96] = vec3(3,-2,-1);
    spheres[97] = vec3(3,-2,0);
    spheres[98] = vec3(3,-2,3);
    spheres[99] = vec3(3,-1,1);
    spheres[100] = vec3(3,1,1);
    spheres[101] = vec3(3,2,0);
    spheres[102] = vec3(3,3,0);
    spheres[103] = vec3(3,5,0);
    spheres[104] = vec3(4,-3,-1);
    spheres[105] = vec3(4,-3,2);
    spheres[106] = vec3(4,-2,-2);
    spheres[107] = vec3(4,3,1);
    spheres[108] = vec3(4,4,0);
    spheres[109] = vec3(5,-2,-2);

    vec4 rgbz = vec4( 0, 0, 0, 10000.0 );
    
    float sphere_radius = 1;

    sphere_hit = -1;
    
    for( int i = 0; i < sphere_count-1; i++ ) {
        vec4 rgbz2 = test_sphere( vec4( 1.0 * spheres[i] * obj2cam - pos, sphere_radius ), ray );
        if( length(rgbz2) > 0. && rgbz2.w < rgbz.w ) {
            rgbz = rgbz2;
            sphere_hit=i;
        }
    }

    //did the ray hit a sphere?    
    if (sphere_hit>-1) { 
        /** 
		//darken based on which sphere is hit
        //rgbz=rgbz/sphere_hit;
        //now that we have a sphere hit index we should be able to work out the surface normal for lighting?
        //OR use the surface normal to bounce ambient occlusion rays?  that would give a Mitsuba like result?
        //"sphere_hit_point" is the XYZ point the ray hit the sphere
        //"normal" is the normalized normal for sphere surface point hit
        vec3 surface_normal=normalize(sphere_hit_point-spheres[sphere_hit]);
        vec3 light_normal=normalize(sphere_hit_point-light);
        vec3 light_vector=normalize(light-sphere_hit_point);
        //The light contribution is then:contribution = sphereColor * dot(N, L) * lightIntensity / distanceToLight^2;
        //float light_intensity = 1000.0;
        //float distance_to_light = sqrt(pow(sphere_hit_point.x-light.x,2)+pow(sphere_hit_point.y-light.y,2)+pow(sphere_hit_point.z-light.z,2));
        //vec3 contribution = vec3(1.0,1.0,1.0) * dot(surface_normal,light_normal) * light_intensity / pow(distance_to_light,2);
        //rgbz = vec4(contribution,1.0);

        //ambient color - base color of shading
        vec3 diffuse=ambient;
        // find the vector to the light
        //float3 L = normalize( light - pt );
        vec3 VectorToLight = normalize(light-sphere_hit_point);
        // find the vector to the eye
        //float3 E     = normalize( eye   - pt );
        vec3 E=normalize(pos-sphere_hit_point);
        // find the cosine of the angle between light and normal
        //float  NdotL = dot( N, L );
        //NdotL.x=N.x*VectorToLight.x;
        //NdotL.y=N.y*VectorToLight.y;
        //NdotL.z=N.z*VectorToLight.z;
        vec3 NdotL=surface_normal*VectorToLight;
        //NdotL=vec3(dot(vec3(N),vec3(VectorToLight)));
        float DiffuseFactor=NdotL.x+NdotL.y+NdotL.z;
        // find the reflected vector
        //float3 R     = L - 2 * NdotL * N;
        //Reflected.x=lightpositions[0].x-2*DiffuseFactor*N.x;
        //Reflected.y=lightpositions[0].y-2*DiffuseFactor*N.y;
        //Reflected.z=lightpositions[0].z-2*DiffuseFactor*N.z;
        vec3 Reflected=light-2.0*DiffuseFactor*surface_normal;
        //if (DiffuseFactor<0) { DiffuseFactor=0; }
        // compute the illumination using the Phong equation
        diffuse=diffuse*max(DiffuseFactor,0.0);
        //diffuse=diffuse*DiffuseFactor;
        //rgbz=vec4(diffuse,1.0);
        
        //rgbz=vec4(2*light_vector,1.0);
        //rgbz=vec4(1.0/sphere_hit);
		**/
    } else {
        //red for no spheres hit background color
        rgbz=vec4(1.0,0.0,0.0,1.0);
    }

    gl_FragColor = vec4( rgbz.xyz, 1 );
    
}
