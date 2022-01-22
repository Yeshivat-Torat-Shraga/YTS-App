export interface LoadData {
  metadata: {
    lastLoadedDocID: string;
    includesLastElement: boolean;
    error?: string;
  };
  content: any[] | null;
}

export interface NewsDocument {
  id: string;
  title: string;
  author: string;
  body: string;
  uploaded: Date;
  imageURLs: string[] | null;
}

export interface SlideshowImageDocument {
  url: string;
  id: string;
  title: string | null;
  uploaded: Date;
}

export interface RebbeimDocument {
  id: string;
  name: string;
  profile_picture_url: string;
}

export interface ContentDocument {
  id: string;
  attributionID: string;
  title: string;
  description: string;
  duration: number;
  date: Date;
  type: string;
  source_url: string;
  author: Author;
}

export interface NewsFirebaseDocument {
  author: string;
  body: string;
  date: Date;
  imageURLs: string[];
  title: string;
}

export interface SlideshowImageFirebaseDocument {
  /** The name of the file inside of the cloud storage folder */
  image_name: string;
  title: string;
  uploaded: Date;
}

export interface RebbeimFirebaseDocument {
  name: string;
  profile_picture_filename: string;
  search_index: string;
}

export interface ContentFirebaseDocument {
  attributionID: string;
  author: string;
  date: Date;
  description: string;
  duration: number;
  search_index: string[];
  source_path: string;
  tags: string[];
  title: string;
  type: string;
}

export interface Author {
  id: string;
  name: string;
  profile_picture_filename: string;
  profile_picture_url?: string;
}
