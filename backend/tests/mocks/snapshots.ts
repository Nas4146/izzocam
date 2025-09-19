// Mock snapshot data for testing
export const mockSnapshots = [
  {
    timestamp: '2025-09-19T10:00:00Z',
    burstId: 'burst-001',
    gcsPaths: ['snapshots/2025-09-19/10-00-frame1.jpg', 'snapshots/2025-09-19/10-00-frame2.jpg'],
    capturedAt: new Date('2025-09-19T10:00:00Z'),
    metadata: {
      width: 1920,
      height: 1080,
      frameCount: 5
    }
  },
  {
    timestamp: '2025-09-19T10:05:00Z',
    burstId: 'burst-002',
    gcsPaths: ['snapshots/2025-09-19/10-05-frame1.jpg', 'snapshots/2025-09-19/10-05-frame2.jpg'],
    capturedAt: new Date('2025-09-19T10:05:00Z'),
    metadata: {
      width: 1920,
      height: 1080,
      frameCount: 5
    }
  },
  {
    timestamp: '2025-09-19T10:10:00Z',
    burstId: 'burst-003',
    gcsPaths: ['snapshots/2025-09-19/10-10-frame1.jpg', 'snapshots/2025-09-19/10-10-frame2.jpg'],
    capturedAt: new Date('2025-09-19T10:10:00Z'),
    metadata: {
      width: 1920,
      height: 1080,
      frameCount: 5
    }
  }
];

// Mock base64 image data (small test image)
export const mockBase64Image = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=';

export const mockImageBuffer = Buffer.from(mockBase64Image.split(',')[1], 'base64');