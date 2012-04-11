/*
	Copyright (c) 2011, T. Kroes <t.kroes@tudelft.nl>
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
	- Neither the name of the TU Delft nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
	
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#pragma once

#include <cuda_runtime.h>

#include "Shape.cuh"
#include "MonteCarlo.cuh"
#include "TransferFunction.cuh"
#include "Tracer.cuh"
#include "Volume.cuh"
										
namespace ExposureRender
{

HOST_DEVICE float GlossinessExponent(const float& Glossiness)
{
	return 1000000.0f * powf(Glossiness, 7);
}

HOST_DEVICE_NI Vec3f ToVec3f(float3 V)
{
	return Vec3f(V.x, V.y, V.z);
}

HOST_DEVICE_NI Vec3f ToVec3f(float V[3])
{
	return Vec3f(V[0], V[1], V[2]);
}

HOST_DEVICE_NI float3 FromVec3f(Vec3f V)
{
	return make_float3(V[0], V[1], V[2]);
}

HOST_DEVICE_NI ColorXYZf ToColorXYZf(float V[3])
{
	return ColorXYZf(V[0], V[1], V[2]);
}



/*
DEVICE bool Inside(ErClippingObject& ClippingObject, Vec3f P)
{
	bool Inside = false;

	switch (ClippingObject.Shape.Type)
	{
		case 0:		
		{
			Inside = InsidePlane(P);
			break;
		}

		case 1:
		{
			Inside = InsideBox(P, ToVec3f(ClippingObject.Shape.Size));
			break;
		}

		case 2:
		{
			Inside = InsideSphere(P, ClippingObject.Shape.OuterRadius);
			break;
		}

		case 3:
		{
			Inside = InsideCylinder(P, ClippingObject.Shape.OuterRadius, ClippingObject.Shape.Size[1]);
			break;
		}
	}

	return ClippingObject.Invert ? !Inside : Inside;
}

DEVICE bool Inside(const Vec3f& P)
{
	for (int i = 0; i < GetTracer().ClippingObjects.Count; i++)
	{
		const Vec3f P2 = TransformPoint(GetTracer().ClippingObjects.List[i].Shape.InvTM, P);

		if (Inside(GetTracer().ClippingObjects.List[i], P2))
			return true;
	}

	return false;
}
*/

DEVICE ColorRGBuc ToneMap(ColorXYZAf XYZA)
{
	ColorRGBf RgbHdr;

	RgbHdr.FromXYZ(XYZA.GetX(), XYZA.GetY(), XYZA.GetZ());

	RgbHdr.SetR(ExposureRender::Clamp(1.0f - expf(-(RgbHdr.GetR() * GetTracer().Camera.InvExposure)), 0.0, 1.0f));
	RgbHdr.SetG(ExposureRender::Clamp(1.0f - expf(-(RgbHdr.GetG() * GetTracer().Camera.InvExposure)), 0.0, 1.0f));
	RgbHdr.SetB(ExposureRender::Clamp(1.0f - expf(-(RgbHdr.GetB() * GetTracer().Camera.InvExposure)), 0.0, 1.0f));
	
	ColorRGBuc Result;

	Result.SetR((unsigned char)ExposureRender::Clamp((255.0f * powf(RgbHdr.GetR(), GetTracer().Camera.InvGamma)), 0.0f, 255.0f));
	Result.SetG((unsigned char)ExposureRender::Clamp((255.0f * powf(RgbHdr.GetG(), GetTracer().Camera.InvGamma)), 0.0f, 255.0f));
	Result.SetB((unsigned char)ExposureRender::Clamp((255.0f * powf(RgbHdr.GetB(), GetTracer().Camera.InvGamma)), 0.0f, 255.0f));

	return Result;
}

DEVICE float G(Vec3f P1, Vec3f N1, Vec3f P2, Vec3f N2)
{
	const Vec3f W = Normalize(P2 - P1);
	return (ClampedDot(W, N1) * ClampedDot(-1.0f * W, N2)) / DistanceSquared(P1, P2);
}

DEVICE ColorXYZAf CumulativeMovingAverage(const ColorXYZAf& A, const ColorXYZAf& Ax, const int& N)
{
	return A + (Ax - A) / max((float)N, 1.0f);
}

DEVICE ColorXYZf CumulativeMovingAverage(const ColorXYZf& A, const ColorXYZf& Ax, const int& N)
{
	 return A + ((Ax - A) / max((float)N, 1.0f));
}

}
