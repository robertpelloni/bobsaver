
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
